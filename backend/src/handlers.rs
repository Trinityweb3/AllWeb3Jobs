use axum::{http::StatusCode, Json};
use serde::Deserialize;
use std::env;
use crate::jobs;
use axum::response::IntoResponse;
#[derive(Deserialize)]
pub struct AddJobRequest {
    pub text: String,
    pub category: String,
}

#[derive(Deserialize)]
pub struct AddContentRequest {
    pub text: String,
    pub category: String,
    pub token_symbol: Option<String>,
    pub image_url: Option<String>,
}

pub async fn add_job(
    headers: axum::http::HeaderMap,
    Json(payload): Json<AddJobRequest>,
) -> impl axum::response::IntoResponse {
    let token = headers.get("x-bot-token").and_then(|v| v.to_str().ok()).unwrap_or("");
    let expected = env::var("BOT_API_SECRET").unwrap_or_default();
    if token != expected {
        return (StatusCode::UNAUTHORIZED, Json(serde_json::json!({"error":"Invalid token"}))).into_response();
    }

    let lines: Vec<&str> = payload.text.trim().lines().collect();
    let title = lines.first().map(|s| *s).unwrap_or("Untitled");
    let description_full = if lines.len() > 1 {
        lines[1..].join("\n").trim().to_string()
    } else {
        title.to_string()
    };

    match jobs::create_job(title, &description_full, &payload.category) {
        Ok(job) => (StatusCode::CREATED, Json(serde_json::json!({"success":true,"slug":job.slug}))).into_response(),
        Err(e) => {
            eprintln!("[add-job] error: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error":e.to_string()}))).into_response()
        }
    }
}

pub async fn add_content(
    headers: axum::http::HeaderMap,
    Json(payload): Json<AddContentRequest>,
) -> impl axum::response::IntoResponse {
    let token = headers.get("x-bot-token").and_then(|v| v.to_str().ok()).unwrap_or("");
    let expected = env::var("BOT_API_SECRET").unwrap_or_default();
    if token != expected {
        return (StatusCode::UNAUTHORIZED, Json(serde_json::json!({"error":"Invalid token"}))).into_response();
    }

    let lines: Vec<&str> = payload.text.trim().lines().collect();
    let title = lines.first().map(|s| *s).unwrap_or("Untitled");
    let description = if lines.len() > 1 {
        lines[1..].join("\n").trim().to_string()
    } else {
        title.to_string()
    };

    let category = payload.category.clone();
    let (dir, post_type) = match category.as_str() {
        "intern" | "mid" => (jobs::JOBS_DIR, "job"),
        _ => (jobs::CONTENT_DIR, &category as &str),
    };

    match jobs::create_post(
        post_type,
        title,
        &description,
        &category,
        payload.token_symbol,
        payload.image_url,
        dir,
    ) {
        Ok(slug) => (StatusCode::CREATED, Json(serde_json::json!({"success":true,"slug":slug}))).into_response(),
        Err(e) => {
            eprintln!("[add-content] error: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error":e.to_string()}))).into_response()
        }
    }
}
