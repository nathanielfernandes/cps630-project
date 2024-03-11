use std::sync::Arc;

use axum::extract::ws::{Message, WebSocket};
use futures::{
    channel::mpsc::{UnboundedReceiver, UnboundedSender},
    stream::SplitSink,
    SinkExt, StreamExt,
};
use moka::future::Cache;
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, RwLock};
use uuid::Uuid;

pub type SocketId = usize;
pub type Error = Box<dyn std::error::Error + Send + Sync>;

#[derive(Clone, Debug)]
pub struct TaggedMessage<T: for<'a> Deserialize<'a> + Send + Sync> {
    pub socket_id: SocketId,
    pub user_id: Option<Uuid>,
    pub message: T,
}

pub type Socket = Arc<SocketInner>;
pub struct SocketInner {
    pub id: SocketId,
    pub user_id: RwLock<Option<Uuid>>,
    sink: Mutex<SplitSink<WebSocket, Message>>,
}

impl SocketInner {
    pub fn new(sink: SplitSink<WebSocket, Message>) -> (Socket, SocketId) {
        let id = fastrand::usize(..);
        (
            Arc::new(Self {
                id,
                user_id: RwLock::new(None),
                sink: Mutex::new(sink),
            }),
            id,
        )
    }

    pub async fn send(self: &Arc<Self>, message: String) -> Result<(), axum::Error> {
        self.sink.lock().await.send(Message::Text(message)).await
    }

    pub async fn authenticate(self: &Arc<Self>, user_id: Uuid) {
        self.user_id.write().await.replace(user_id);
    }

    pub async fn user_id(self: &Arc<Self>) -> Option<Uuid> {
        self.user_id.read().await.clone()
    }
}

pub type Client = Arc<ClientInner>;
pub struct ClientInner(RwLock<Vec<Socket>>);

impl ClientInner {
    pub fn new(socket: Socket) -> Client {
        Arc::new(Self(RwLock::new(vec![socket])))
    }

    pub async fn add_socket(self: &Client, socket: Socket) {
        self.0.write().await.push(socket);
    }

    pub async fn remove_socket(self: &Client, socket_id: SocketId) -> usize {
        let mut sockets = self.0.write().await;
        if let Some(pos) = sockets.iter().position(|s| s.id == socket_id) {
            sockets.remove(pos);
        }

        sockets.len()
    }

    pub async fn send(self: &Client, message: String) {
        let sockets = self.0.read().await;
        for socket in sockets.iter() {
            if let Err(e) = socket.send(message.clone()).await {
                println!("Error sending message to socket {}: {}", socket.id, e);
                self.remove_socket(socket.id).await;
            }
        }
    }
}

pub struct WsPool<T: for<'a> Deserialize<'a> + Send + Sync> {
    authenticated: Cache<Uuid, Client>,
    sockets: Cache<SocketId, Socket>,
    subscriber: UnboundedSender<TaggedMessage<T>>,
}

impl<T: for<'a> Deserialize<'a> + Send + Sync> WsPool<T> {
    pub fn new() -> (&'static WsPool<T>, UnboundedReceiver<TaggedMessage<T>>) {
        let (tx, rx) = futures::channel::mpsc::unbounded();
        (
            leak(Self {
                sockets: Cache::builder().build(),
                authenticated: Cache::builder().build(),
                subscriber: tx,
            }),
            rx,
        )
    }

    pub async fn add_connection(&'static self, websocket: WebSocket) {
        let (sink, mut stream) = websocket.split();
        let (socket, socket_id) = SocketInner::new(sink);

        self.add_socket(socket.clone()).await;

        tokio::task::spawn(async move {
            let mut subscriber = self.subscriber.clone();
            while let Some(message) = stream.next().await {
                let result: Result<(), Error> = try {
                    match message? {
                        Message::Text(text) => {
                            let user_id = socket.user_id().await;

                            let message: T = match serde_json::from_str(&text) {
                                Ok(msg) => msg,
                                Err(e) => {
                                    println!("Error parsing message: {}", e);
                                    continue;
                                }
                            };

                            let tagged_message = TaggedMessage {
                                socket_id,
                                user_id,
                                message,
                            };

                            subscriber.send(tagged_message).await?;
                        }
                        Message::Close(_) => {
                            break;
                        }
                        _ => {}
                    }
                };

                if let Err(e) = result {
                    println!("Error sending message: {}", e);
                    break;
                }
            }

            println!("Socket disconnected");
            self.remove_socket(socket_id).await;
        });
    }

    async fn add_socket(&'static self, socket: Socket) {
        self.sockets.insert(socket.id, socket).await;
    }

    async fn remove_socket(&'static self, socket_id: SocketId) {
        let Some(socket) = self.sockets.remove(&socket_id).await else {
            return;
        };

        let Some(user_id) = socket.user_id().await else {
            return;
        };

        let Some(client) = self.authenticated.get(&user_id).await else {
            return;
        };

        let open_sockets = client.remove_socket(socket_id).await;

        if open_sockets == 0 {
            self.authenticated.remove(&user_id).await;
        }
    }

    pub async fn authenticate(&'static self, user_id: Uuid, socket_id: SocketId) {
        let Some(socket) = self.sockets.get(&socket_id).await else {
            return;
        };

        socket.authenticate(user_id).await;

        // if the user is already authenticated, add the socket to the client
        match self.authenticated.get(&user_id).await {
            Some(client) => {
                client.add_socket(socket).await;
            }
            None => {
                let client = ClientInner::new(socket);
                self.authenticated.insert(user_id, client).await;
            }
        }
    }

    pub async fn send_to_user<M>(&'static self, user_id: Uuid, message: M) -> Result<(), Error>
    where
        M: Serialize,
    {
        let Some(client) = self.authenticated.get(&user_id).await else {
            return Ok(());
        };

        let message = serde_json::to_string(&message)?;
        client.send(message).await;

        Ok(())
    }

    pub async fn send_to_socket<M>(
        &'static self,
        socket_id: SocketId,
        message: M,
    ) -> Result<(), Error>
    where
        M: Serialize,
    {
        let Some(socket) = self.sockets.get(&socket_id).await else {
            return Ok(());
        };

        let message = serde_json::to_string(&message)?;

        socket.send(message).await.map_err(|e| e.into())
    }

    pub async fn send_to_users<M>(&'static self, user_ids: &[Uuid], message: M) -> Result<(), Error>
    where
        M: Serialize,
    {
        let message = serde_json::to_string(&message)?;
        for user_id in user_ids {
            if let Some(client) = self.authenticated.get(user_id).await {
                client.send(message.clone()).await;
            }
        }

        Ok(())
    }
}

// LMAOOOOOOOOOOO, idgaf
// im leaking memory to avoid useless Arcs
// these are never going to be dropped
pub fn leak<T>(t: T) -> &'static T {
    Box::leak(Box::new(t))
}
