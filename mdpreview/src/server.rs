use axum::extract::State;
use axum::response::{Html, IntoResponse};
use axum::{
    routing::{get, post},
    Router,
};
use tokio::sync::broadcast;
use tower_http::services::ServeDir;

use crate::state::AppState;
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

pub async fn run() {
    let (tx, _) = broadcast::channel::<String>(100);

    let state = AppState {
        html: std::sync::Arc::new(std::sync::Mutex::new(String::new())),
        tx,
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
        .route("/update", post(update_markdown))
        .nest_service("/static", ServeDir::new(static_path))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:3000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}

pub async fn update_markdown(State(state): State<AppState>, body: String) {
    let html = crate::markdown::to_html(&body);
    {
        let mut html_lock = state.html.lock().unwrap();
        *html_lock = html.clone();
    }

    let _ = state.tx.send(html);
}
