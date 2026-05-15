use teloxide::prelude::*;
use reqwest::Client;
use std::env;

pub async fn start_bots() {
    // Клиент для Telegram API (пойдёт через глобальный прокси, если он задан)
    let telegram_client = Client::new();
    // Клиент для запросов к localhost/внутреннему API – БЕЗ прокси
    let local_client = Client::builder()
        .no_proxy()
        .build()
        .expect("Failed to build local HTTP client");

    let api_url =
        env::var("API_URL").unwrap_or_else(|_| "http://localhost:3001/api/add-job".to_string());
    let bot1_token = env::var("BOT1_TOKEN").expect("BOT1_TOKEN missing");
    let bot2_token = env::var("BOT2_TOKEN").expect("BOT2_TOKEN missing");
    let bot_api_secret = env::var("BOT_API_SECRET").expect("BOT_API_SECRET missing");

    println!("DEBUG: API_URL = {}", api_url);
    println!("DEBUG: BOT_API_SECRET = {}", bot_api_secret);

    let bot1 = Bot::new(bot1_token);
    let bot2 = Bot::new(bot2_token);

    let handler1 = {
        let local_client = local_client.clone();
        let api_url = api_url.clone();
        let secret = bot_api_secret.clone();
        let bot1 = bot1.clone();
        Update::filter_message().branch(
            dptree::entry()
                .filter_map(|msg: Message| msg.text().map(|text| (msg.chat.id, text.to_owned())))
                .endpoint(move |(chat_id, text): (ChatId, String)| {
                    let local_client = local_client.clone();
                    let api_url = api_url.clone();
                    let secret = secret.clone();
                    let bot1 = bot1.clone();
                    async move {
                        let result_msg = send_job_with_debug(
                            &local_client,
                            &api_url,
                            &text,
                            "internships-juniors",
                            &secret,
                        )
                        .await;
                        bot1.send_message(chat_id, result_msg).await?;
                        respond(())
                    }
                }),
        )
    };

    let handler2 = {
        let local_client = local_client.clone();
        let api_url = api_url.clone();
        let secret = bot_api_secret.clone();
        let bot2 = bot2.clone();
        Update::filter_message().branch(
            dptree::entry()
                .filter_map(|msg: Message| msg.text().map(|text| (msg.chat.id, text.to_owned())))
                .endpoint(move |(chat_id, text): (ChatId, String)| {
                    let local_client = local_client.clone();
                    let api_url = api_url.clone();
                    let secret = secret.clone();
                    let bot2 = bot2.clone();
                    async move {
                        let result_msg = send_job_with_debug(
                            &local_client,
                            &api_url,
                            &text,
                            "mid-senior-leads",
                            &secret,
                        )
                        .await;
                        bot2.send_message(chat_id, result_msg).await?;
                        respond(())
                    }
                }),
        )
    };

    let mut dispatcher1 = Dispatcher::builder(bot1, handler1)
        .enable_ctrlc_handler()
        .build();
    let mut dispatcher2 = Dispatcher::builder(bot2, handler2)
        .enable_ctrlc_handler()
        .build();

    tokio::join!(dispatcher1.dispatch(), dispatcher2.dispatch());
}

async fn send_job_with_debug(
    client: &Client,
    api_url: &str,
    text: &str,
    category: &str,
    secret: &str,
) -> String {
    let payload = serde_json::json!({
        "text": text,
        "category": category,
    });

    let response = client
        .post(api_url)
        .header("x-bot-token", secret)
        .json(&payload)
        .send()
        .await;

    match response {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.text().await.unwrap_or_else(|e| format!("body read error: {}", e));
            format!("API status: {}\nResponse body: {}", status, body)
        }
        Err(e) => {
            format!(
                "Request failed: {}\nURL: {}\nSecret: {}",
                e, api_url, secret
            )
        }
    }
}