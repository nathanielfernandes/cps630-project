use futures::{channel::mpsc::UnboundedReceiver, StreamExt};
use moka::future::Cache;
use reqwest::Client;
use std::sync::Arc;
use tokio::sync::RwLock;

use uuid::Uuid;

use crate::{
    history::History,
    messages::{ChatMessage, ClientMessage, ServerErrors, ServerMessage},
    ws::{leak, SocketId, TaggedMessage, WsPool},
};

pub struct HistoryManager(Cache<String, Arc<RwLock<History<ChatMessage>>>>);

impl HistoryManager {
    const HISTORY_SIZE: usize = 100;

    pub fn new() -> Self {
        Self(Cache::builder().build())
    }

    pub fn history_id(a: &Uuid, b: &Uuid) -> String {
        if a < b {
            format!("{}-{}", a, b)
        } else {
            format!("{}-{}", b, a)
        }
    }

    pub async fn get_history(&self, history_id: &str) -> Arc<RwLock<History<ChatMessage>>> {
        self.0
            .get_with_by_ref(history_id, async {
                Arc::new(RwLock::new(History::new(Self::HISTORY_SIZE)))
            })
            .await
    }

    pub async fn push_message(&self, from: &Uuid, to: &Uuid, message: ChatMessage) {
        let history_id = Self::history_id(from, to);
        self.get_history(&history_id)
            .await
            .write()
            .await
            .push(message);
    }

    pub async fn get_messages(&self, from: &Uuid, to: &Uuid) -> Vec<ChatMessage> {
        let history_id = Self::history_id(from, to);
        self.get_history(&history_id).await.read().await.to_vec()
    }
}

pub struct ChatManager {
    pub wspool: &'static WsPool<ClientMessage>,
    pub history: HistoryManager,

    client: Client,
    auth_endpoint: String,
    token: String,
}

impl ChatManager {
    pub fn new(wsroom: &'static WsPool<ClientMessage>) -> &'static Self {
        leak(Self {
            wspool: wsroom,
            history: HistoryManager::new(),
            client: Client::new(),
            token: std::env::var("TOKEN").expect("TOKEN not set"),
            auth_endpoint: std::env::var("AUTH_ENDPOINT").expect("AUTH_ENDPOINT not set"),
        })
    }

    async fn send_message(&self, from: Uuid, to: Uuid, message: String) {
        let cm = ChatMessage::User {
            from: from.to_string(),
            message,
        };

        let message = ServerMessage::DirectMessage {
            message: cm.clone(),
        };

        self.history.push_message(&from, &to, cm).await;
        if let Err(e) = self.wspool.send_to_users(&[from, to], message).await {
            println!("Failed to send message: {}", e);
        }
    }

    pub fn start(&'static self, mut rx: UnboundedReceiver<TaggedMessage<ClientMessage>>) {
        tokio::spawn(async move {
            while let Some(TaggedMessage {
                socket_id,
                user_id,
                message,
            }) = rx.next().await
            {
                match message {
                    ClientMessage::DirectMessage { to, message } => {
                        // If the user is not logged in, we can't do anything
                        let Some(from) = user_id else {
                            self.send_error(socket_id, ServerErrors::Unauthorized).await;
                            continue;
                        };

                        let Ok(to) = Uuid::parse_str(&to) else {
                            self.send_error(socket_id, ServerErrors::InvalidUuid).await;
                            continue;
                        };

                        self.send_message(from, to, message).await
                    }
                    ClientMessage::SyncChat { with } => {
                        // If the user is not logged in, we can't do anything
                        let Some(from) = user_id else {
                            self.send_error(socket_id, ServerErrors::Unauthorized).await;
                            continue;
                        };

                        let Ok(with) = Uuid::parse_str(&with) else {
                            self.send_error(socket_id, ServerErrors::InvalidUuid).await;
                            continue;
                        };

                        let messages = self.history.get_messages(&from, &with).await;
                        let message = ServerMessage::BulkMessages {
                            from: with.to_string(),
                            messages,
                        };

                        if let Err(e) = self.wspool.send_to_user(from, message).await {
                            println!("Failed to send chat history: {}", e);
                        }
                    }
                    ClientMessage::Ping => {
                        let message = ServerMessage::Pong;
                        if let Err(e) = self.wspool.send_to_socket(socket_id, message).await {
                            println!("Failed to send pong: {}", e);
                        }
                    }

                    ClientMessage::Authenticate { id, secret } => {
                        println!("Authentication Attempt: {}", id);
                        if let Some(_) = user_id {
                            self.send_error(socket_id, ServerErrors::AlreadyAuthenticated)
                                .await;
                            continue;
                        }

                        let Ok(id) = Uuid::parse_str(&id) else {
                            self.send_error(socket_id, ServerErrors::InvalidUuid).await;
                            continue;
                        };

                        if !self.verify_secret(&id.to_string(), &secret).await {
                            self.send_error(socket_id, ServerErrors::InvalidSecret)
                                .await;
                            continue;
                        }

                        self.wspool.authenticate(id, socket_id).await;

                        let message = ServerMessage::Authenticated;
                        println!("Authenticated: {}", id);
                        if let Err(e) = self.wspool.send_to_socket(socket_id, message).await {
                            println!("Failed to send authenticated: {}", e);
                        }
                    }
                    ClientMessage::Disconnect => {
                        self.wspool.remove_socket(socket_id).await;
                    }
                }
            }
        });
    }

    async fn send_error(&self, socket_id: SocketId, error: ServerErrors) {
        let message = ServerMessage::Error(error);
        if let Err(e) = self.wspool.send_to_socket(socket_id, message).await {
            println!("Failed to send error: {}", e);
        }
    }

    async fn verify_secret(&self, uuid: &str, secret: &str) -> bool {
        let resp = self
            .client
            .get(&format!("{}/{}", self.auth_endpoint, uuid))
            .header("Secret", secret)
            .header("Token", &self.token)
            .send()
            .await;

        match resp {
            Ok(resp) => resp.status().is_success(),
            Err(_) => false,
        }
    }
}
