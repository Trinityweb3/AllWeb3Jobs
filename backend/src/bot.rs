use std::collections::HashMap;
use std::env;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use teloxide::{
    prelude::*,
    types::{KeyboardButton, KeyboardMarkup, Message, ReplyMarkup},
    RequestError,
};
use reqwest::Client;
use uuid::Uuid;

const SECTION_INTERN: &str = "🧑‍💻 Intern/Junior Job";
const SECTION_MID: &str = "💼 Mid/Senior Job";
const SECTION_NEWS: &str = "📰 News";
const SECTION_ACTIVITY: &str = "🎯 Activity";
const SECTION_TOKEN: &str = "📊 Token Analysis";
const CANCEL: &str = "❌ Cancel";

#[derive(Clone)]
enum PendingAction {
    Content {
        category: String,
        token_symbol: Option<String>,
    },
    AwaitTokenSymbol,
}

type WaitingMap = Arc<Mutex<HashMap<ChatId, PendingAction>>>;

fn get_allowed_users() -> Vec<String> {
    env::var("ALLOWED_USERS")
        .unwrap_or_default()
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

fn is_user_allowed(chat_id: &ChatId) -> bool {
    let allowed = get_allowed_users();
    if allowed.is_empty() {
        return true;
    }
    let user_id = chat_id.to_string();
    allowed.iter().any(|id| id == &user_id)
}

fn main_keyboard() -> ReplyMarkup {
    let keyboard = vec![
        vec![
            KeyboardButton::new(SECTION_INTERN),
            KeyboardButton::new(SECTION_MID),
        ],
        vec![
            KeyboardButton::new(SECTION_NEWS),
            KeyboardButton::new(SECTION_ACTIVITY),
        ],
        vec![KeyboardButton::new(SECTION_TOKEN)],
        vec![KeyboardButton::new(CANCEL)],
    ];
    ReplyMarkup::Keyboard(KeyboardMarkup::new(keyboard).resize_keyboard())
}

pub async fn start_bot() {
    let token = env::var("BOT_TOKEN").expect("BOT_TOKEN missing");
    let bot = Bot::new(token);

    let telegram_http_client = Arc::new(Client::new());

    let local_http_client = Arc::new(
        Client::builder()
            .no_proxy()
            .build()
            .expect("Failed to build local HTTP client"),
    );

    let api_url =
        env::var("API_URL").unwrap_or_else(|_| "http://localhost:3001/api/add-content".to_string());
    let public_dir = PathBuf::from(
        env::var("PUBLIC_DIR").unwrap_or_else(|_| "../frontend/public/images".to_string()),
    );
    let public_dir = Arc::new(public_dir);
    let waiting: WaitingMap = Arc::new(Mutex::new(HashMap::new()));

    let handler = {
        let bot = bot.clone();
        let local_http_client = local_http_client.clone();
        let telegram_http_client = telegram_http_client.clone();
        let api_url = api_url.clone();
        let public_dir = public_dir.clone();
        let waiting = waiting.clone();

        Update::filter_message()
            .filter(|msg: Message| is_user_allowed(&msg.chat.id))
            .branch(dptree::endpoint(
                move |msg: Message, bot: Bot| {
                    let bot = bot.clone();
                    let local_http_client = local_http_client.clone();
                    let telegram_http_client = telegram_http_client.clone();
                    let api_url = api_url.clone();
                    let public_dir = public_dir.clone();
                    let waiting = waiting.clone();

                    async move {
                        let chat_id = msg.chat.id;
                        let text = msg.text().or(msg.caption()).unwrap_or("").to_string();

                        if text == CANCEL {
                            waiting.lock().unwrap().remove(&chat_id);
                            bot.send_message(chat_id, "Action cancelled. Choose a section:")
                                .reply_markup(main_keyboard())
                                .await?;
                            return Ok::<_, RequestError>(());
                        }

                        let pending = {
                            let lock = waiting.lock().unwrap();
                            lock.get(&chat_id).cloned()
                        };

                        if let Some(pending) = pending {
                            match pending {
                                PendingAction::Content {
                                    category,
                                    token_symbol,
                                } => {
                                    if text.is_empty() && msg.photo().is_none() {
                                        bot.send_message(
                                            chat_id,
                                            "Please send text (or photo with caption)",
                                        )
                                        .await?;
                                    } else {
                                        let mut image_url = String::new();
                                        if let Some(photo) =
                                            msg.photo().and_then(|photos| photos.last())
                                        {
                                            match bot.get_file(&photo.file.id).await {
                                                Ok(file) => {
                                                    let ext = std::path::Path::new(&file.path)
                                                        .extension()
                                                        .unwrap_or_default()
                                                        .to_str()
                                                        .unwrap_or("jpg");
                                                    let filename =
                                                        format!("{}.{}", Uuid::new_v4(), ext);
                                                    let save_path = public_dir.join(&filename);
                                                    let file_url = format!(
                                                        "https://api.telegram.org/file/bot{}/{}",
                                                        bot.token(),
                                                        file.path
                                                    );
                                                    match telegram_http_client
                                                        .clone()
                                                        .get(&file_url)
                                                        .send()
                                                        .await
                                                    {
                                                        Ok(resp) => match resp.bytes().await {
                                                            Ok(bytes) => {
                                                                if let Err(e) = tokio::fs::write(
                                                                    &save_path,
                                                                    &bytes,
                                                                )
                                                                .await
                                                                {
                                                                    bot.send_message(
                                                                        chat_id,
                                                                        format!(
                                                                            "❌ File save error: {}",
                                                                            e
                                                                        ),
                                                                    )
                                                                    .await?;
                                                                    return Ok::<_, RequestError>(
                                                                        (),
                                                                    );
                                                                }
                                                                image_url = format!(
                                                                    "/images/{}",
                                                                    filename
                                                                );
                                                            }
                                                            Err(e) => {
                                                                bot.send_message(
                                                                    chat_id,
                                                                    format!(
                                                                        "❌ Download error: {}",
                                                                        e
                                                                    ),
                                                                )
                                                                .await?;
                                                                return Ok::<_, RequestError>(
                                                                    (),
                                                                );
                                                            }
                                                        },
                                                        Err(e) => {
                                                            bot.send_message(
                                                                chat_id,
                                                                format!(
                                                                    "❌ Network error: {}",
                                                                    e
                                                                ),
                                                            )
                                                            .await?;
                                                            return Ok::<_, RequestError>(());
                                                        }
                                                    }
                                                }
                                                Err(e) => {
                                                    bot.send_message(
                                                        chat_id,
                                                        format!(
                                                            "❌ Telegram file error: {}",
                                                            e
                                                        ),
                                                    )
                                                    .await?;
                                                    return Ok::<_, RequestError>(());
                                                }
                                            }
                                        }

                                        let payload = serde_json::json!({
                                            "text": text,
                                            "category": category,
                                            "token_symbol": token_symbol,
                                            "image_url": image_url,
                                        });

                                        match local_http_client
                                            .clone()
                                            .post(&api_url)
                                            .header(
                                                "x-bot-token",
                                                env::var("BOT_API_SECRET")
                                                    .expect("BOT_API_SECRET missing"),
                                            )
                                            .json(&payload)
                                            .send()
                                            .await
                                        {
                                            Ok(resp) => {
                                                if resp.status().is_success() {
                                                    bot.send_message(
                                                        chat_id,
                                                        "✅ Content posted!",
                                                    )
                                                    .await?;
                                                } else {
                                                    let body = resp
                                                        .text()
                                                        .await
                                                        .unwrap_or_else(|_| {
                                                            "Unknown error".into()
                                                        });
                                                    bot.send_message(
                                                        chat_id,
                                                        format!("❌ API error: {}", body),
                                                    )
                                                    .await?;
                                                }
                                            }
                                            Err(e) => {
                                                bot.send_message(
                                                    chat_id,
                                                    format!("❌ Request failed: {}", e),
                                                )
                                                .await?;
                                            }
                                        }

                                        waiting.lock().unwrap().remove(&chat_id);
                                        bot.send_message(chat_id, "Choose next action:")
                                            .reply_markup(main_keyboard())
                                            .await?;
                                    }
                                }
                                PendingAction::AwaitTokenSymbol => {
                                    if text.is_empty() {
                                        bot.send_message(
                                            chat_id,
                                            "Please type the token symbol (e.g. BTC):",
                                        )
                                        .await?;
                                    } else {
                                        let symbol = text.trim().to_uppercase();
                                        bot.send_message(
                                            chat_id,
                                            format!(
                                                "Now send text + optional photo for token ${}",
                                                symbol
                                            ),
                                        )
                                        .await?;
                                        waiting.lock().unwrap().insert(
                                            chat_id,
                                            PendingAction::Content {
                                                category: "token_analysis".into(),
                                                token_symbol: Some(symbol),
                                            },
                                        );
                                    }
                                }
                            }
                        } else {
                            match text.as_str() {
                                SECTION_INTERN => {
                                    bot.send_message(
                                        chat_id,
                                        "Send text + optional photo for Intern/Junior job",
                                    )
                                    .await?;
                                    waiting.lock().unwrap().insert(
                                        chat_id,
                                        PendingAction::Content {
                                            category: "intern".into(),
                                            token_symbol: None,
                                        },
                                    );
                                }
                                SECTION_MID => {
                                    bot.send_message(
                                        chat_id,
                                        "Send text + optional photo for Mid/Senior job",
                                    )
                                    .await?;
                                    waiting.lock().unwrap().insert(
                                        chat_id,
                                        PendingAction::Content {
                                            category: "mid".into(),
                                            token_symbol: None,
                                        },
                                    );
                                }
                                SECTION_NEWS => {
                                    bot.send_message(
                                        chat_id,
                                        "Send text + optional photo for a news post",
                                    )
                                    .await?;
                                    waiting.lock().unwrap().insert(
                                        chat_id,
                                        PendingAction::Content {
                                            category: "news".into(),
                                            token_symbol: None,
                                        },
                                    );
                                }
                                SECTION_ACTIVITY => {
                                    bot.send_message(
                                        chat_id,
                                        "Send text + optional photo for an activity",
                                    )
                                    .await?;
                                    waiting.lock().unwrap().insert(
                                        chat_id,
                                        PendingAction::Content {
                                            category: "activity".into(),
                                            token_symbol: None,
                                        },
                                    );
                                }
                                SECTION_TOKEN => {
                                    bot.send_message(
                                        chat_id,
                                        "First, type the token symbol (e.g. BTC):",
                                    )
                                    .await?;
                                    waiting.lock().unwrap().insert(
                                        chat_id,
                                        PendingAction::AwaitTokenSymbol,
                                    );
                                }
                                _ => {
                                    bot.send_message(chat_id, "Choose a section:")
                                        .reply_markup(main_keyboard())
                                        .await?;
                                }
                            }
                        }
                        Ok::<_, RequestError>(())
                    }
                },
            ))
    };

    Dispatcher::builder(bot, handler)
        .enable_ctrlc_handler()
        .build()
        .dispatch()
        .await;
}