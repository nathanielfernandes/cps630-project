#![feature(try_blocks)]

use axum::{
    extract::{State, WebSocketUpgrade},
    response::{IntoResponse, Response},
    routing::get,
    Router,
};
use messages::{export_types, ClientMessage};

pub mod history;
pub mod manager;
pub mod messages;
pub mod ws;

const PORT: u16 = 3000;

#[derive(Clone)]
pub struct AppState {
    pub room: &'static ws::WsPool<ClientMessage>,
}

#[tokio::main]
async fn main() {
    #[cfg(debug_assertions)]
    export_types();

    let (room, rx) = ws::WsPool::new();
    manager::ChatManager::new(room).await.start(rx);

    let aps = AppState { room };
    let app = Router::new()
        .route("/", get(root))
        .route("/ws", get(ws_handler))
        .with_state(aps);

    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{PORT}"))
        .await
        .expect(&format!("Failed to bind to port {PORT}"));

    println!("[CHATTER] Listening on port {PORT}");
    axum::serve(listener, app)
        .await
        .expect("Failed to start server");
}

async fn root() -> impl IntoResponse {
    "Hello, World!"
}

async fn ws_handler(ws: WebSocketUpgrade, State(app): State<AppState>) -> Response {
    ws.on_upgrade(move |socket| app.room.add_connection(socket))
}
