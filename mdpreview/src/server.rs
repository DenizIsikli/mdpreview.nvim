use axum::extract::{Query, State};
use axum::http::HeaderMap;
use axum::response::{Html, IntoResponse};
use axum::Json;
use axum::{
    routing::{get, post},
    Router,
};
use std::{collections::HashMap, fs, path::PathBuf};
use tokio::sync::broadcast;
use tower_http::services::ServeDir;

use crate::state::{AppState, CursorPayload};
use crate::websocket::ws_handler;

async fn index() -> impl IntoResponse {
    let exe_dir = std::env::current_exe()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf();

    let static_path = if exe_dir.ends_with("debug") || exe_dir.ends_with("release") {
        exe_dir.join("../../static")
    } else {
        exe_dir.join("../mdpreview/static")
    }
    .canonicalize()
    .unwrap();

    Html(std::fs::read_to_string(static_path.join("index.html")).unwrap())
}

async fn img(
    State(state): State<AppState>,
    Query(params): Query<HashMap<String, String>>,
) -> impl IntoResponse {
    if let Some(path) = params.get("path") {
        let base = state.base_dir.lock().unwrap().clone();

        let full: PathBuf = PathBuf::from(base).join(path);

        if let Ok(bytes) = fs::read(&full) {
            return ([("Content-Type", "image/png")], bytes);
        }
    }

    ([("Content-Type", "text/plain")], b"not found".to_vec())
}

pub async fn update_markdown(State(state): State<AppState>, headers: HeaderMap, body: String) {
    let base_dir = headers
        .get("x-base-dir")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .to_string();

    {
        let mut base = state.base_dir.lock().unwrap();
        *base = base_dir;
    }

    let html = crate::markdown::render_markdown(&body);
    {
        let mut html_lock = state.html.lock().unwrap();
        *html_lock = html.clone();
    }

    let _ = state.tx.send(html);
}

pub async fn update_cursor(State(state): State<AppState>, Json(payload): Json<CursorPayload>) {
    let msg = format!(
        r#"{{"type":"cursor","line":{},"col":{}}}"#,
        payload.line, payload.col
    );

    let _ = state.tx.send(msg);
}

pub async fn run() {
    let (tx, _) = broadcast::channel::<String>(100);

    let state = AppState {
        html: std::sync::Arc::new(std::sync::Mutex::new(String::new())),
        tx,
        base_dir: std::sync::Arc::new(std::sync::Mutex::new(String::new())),
    };

    let exe_dir = std::env::current_exe()
        .unwrap()
        .parent()
        .unwrap()
        .to_path_buf();

    let static_path = if exe_dir.ends_with("debug") || exe_dir.ends_with("release") {
        exe_dir.join("../../static")
    } else {
        exe_dir.join("../mdpreview/static")
    }
    .canonicalize()
    .unwrap();

    let app = Router::new()
        .route("/", get(index))
        .route("/ws", get(ws_handler))
        .route("/img", get(img))
        .route("/update", post(update_markdown))
        .route("/cursor", post(update_cursor))
        .nest_service("/static", ServeDir::new(static_path))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}
