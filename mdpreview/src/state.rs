use std::sync::{Arc, Mutex};
use tokio::sync::broadcast;

#[derive(Clone)]
pub struct AppState {
    pub html: Arc<Mutex<String>>,
    pub tx: broadcast::Sender<String>,
    pub base_dir: Arc<Mutex<String>>,
}
