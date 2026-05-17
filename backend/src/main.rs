mod bot;
mod handlers;
mod jobs;
mod models;

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();
    env_logger::init();

    tokio::spawn(bot::start_bot());

    let app = axum::Router::new()
        .route("/api/add-job", axum::routing::post(handlers::add_job))
        .route("/api/add-content", axum::routing::post(handlers::add_content));

    let port = std::env::var("PORT").unwrap_or_else(|_| "3001".to_string());
    let addr = format!("0.0.0.0:{}", port);
    println!("🚀 Server listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
