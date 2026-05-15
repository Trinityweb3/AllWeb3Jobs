use crate::jobs;
use axum::{extract::State, http::StatusCode, Json};
use serde::Deserialize;
use std::sync::Arc;
 use axum::response::IntoResponse;
pub struct AppState;

#[derive(Deserialize)]
pub struct AddJobRequest {
    pub text: String,
    pub category: String,
}

pub async fn add_job(
    headers: axum::http::HeaderMap,
    Json(payload): Json<AddJobRequest>,
) -> impl axum::response::IntoResponse {
    let token = headers.get("x-bot-token").and_then(|v| v.to_str().ok()).unwrap_or("");
    let expected = std::env::var("BOT_API_SECRET").unwrap_or_default();
    if token != expected {
        return (StatusCode::UNAUTHORIZED, Json(serde_json::json!({"error":"Invalid token"}))).into_response();
    }
    let lines: Vec<&str> = payload.text.trim().lines().collect();
    let title = lines.first().map(|s| *s).unwrap_or("Untitled");
    let desc = if lines.len() > 1 { lines[1..].join("\n") } else { title.to_string() };
    match jobs::create_job(title, &desc, &payload.category) {
        Ok(job) => (StatusCode::CREATED, Json(serde_json::json!({"success":true,"slug":job.slug}))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error":e.to_string()}))).into_response(),
    }
}
