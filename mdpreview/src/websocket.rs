use axum::extract::{
    ws::{Message, WebSocket, WebSocketUpgrade},
    State,
};
use axum::response::IntoResponse;
use tokio::sync::broadcast;

use crate::state::AppState;

pub async fn ws_handler(ws: WebSocketUpgrade, State(state): State<AppState>) -> impl IntoResponse {
    let rx = state.tx.subscribe();
    ws.on_upgrade(move |socket| handle_socket(socket, state, rx))
}

async fn handle_socket(
    mut socket: WebSocket,
    _state: AppState,
    mut rx: broadcast::Receiver<String>,
) {
    let initial_html = {
        let html = _state.html.lock().unwrap();
        html.clone()
    };

    if !initial_html.is_empty() {
        let _ = socket.send(Message::Text(initial_html)).await;
    }

    loop {
        tokio::select! {
            msg = rx.recv() => {
                match msg {
                    Ok(html) => {
                        if socket.send(Message::Text(html)).await.is_err() {
                            break;
                        }
                    }
                    Err(broadcast::error::RecvError::Lagged(_)) => {
                        continue;
                    }
                    Err(_) => break,
                }
            }

            incoming = socket.recv() => {
                match incoming {
                    Some(Ok(Message::Close(_))) | None => break,
                    Some(Ok(_)) => continue,
                    Some(Err(_)) => break,
                }
            }
        }
    }
}
