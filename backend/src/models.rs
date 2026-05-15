use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Job {
    pub slug: String,
    pub title: String,
    pub description_short: String,
    pub description_full: String,
    pub date: String,
    pub category: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub company: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub location: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub job_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CoinData {
    pub id: String,
    pub symbol: String,
    pub name: String,
    pub image: String,
    pub current_price: f64,
    pub price_change_percentage_24h: Option<f64>,
    pub market_cap: f64,
    pub total_volume: f64,
}
