use serde::Deserialize;
use serde::Serialize;
use std::sync::{Arc, Mutex};
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct AppState {
    pub html: Arc<Mutex<String>>,
    pub tx: broadcast::Sender<String>,
    pub base_dir: Arc<Mutex<String>>,
}

#[derive(Deserialize)]
pub struct CursorPayload {
    pub line: usize,
    pub col: usize,
}

#[derive(Serialize)]
pub struct WsMessage {
    pub r#type: String,
    pub html: String,
    pub raw: String,
}
