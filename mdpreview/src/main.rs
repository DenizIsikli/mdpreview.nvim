mod markdown;
mod server;
mod state;
mod websocket;

#[tokio::main]
async fn main() {
    server::run().await;
}
