use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Job {
    pub slug: String,
    pub title: String,
    pub description_short: String,
    pub description_full: String,
    pub date: String,
    pub category: String,
    pub company: Option<String>,
    pub location: Option<String>,
    pub job_type: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Post {
    pub slug: String,
    pub title: String,
    pub description: String,
    pub date: String,
    pub category: String,
    pub post_type: String,           
    pub token_symbol: Option<String>,
    pub image_url: Option<String>,
    pub company: Option<String>,
    pub location: Option<String>,
    pub job_type: Option<String>,
}
