mod bots;
mod handlers;
mod jobs;
mod models;

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();
    env_logger::init();

    // Запускаем ботов в фоновой задаче
    tokio::spawn(bots::start_bots());

    let app = axum::Router::new()
        .route("/api/add-job", axum::routing::post(handlers::add_job));

    let port = std::env::var("PORT").unwrap_or_else(|_| "3001".to_string());
    let addr = format!("0.0.0.0:{}", port);
    println!("🚀 Rust backend listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}