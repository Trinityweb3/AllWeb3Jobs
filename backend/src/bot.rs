use std::collections::HashMap;
use std::env;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use teloxide::{prelude::*, types::Message, utils::command::BotCommands, RequestError};
use reqwest::Client;
use uuid::Uuid;

// Команды бота
#[derive(BotCommands, Clone)]
#[command(rename_rule = "lowercase")]
enum Command {
    Start,
    Help,
    #[command(rename = "/intern")]
    Intern,
    #[command(rename = "/mid")]
    Mid,
    #[command(rename = "/news")]
    News,
    #[command(rename = "/activity")]
    Activity,
    #[command(rename = "/token")]
    Token(String),
    Cancel,
}

// Действие, которое бот ожидает от пользователя
#[derive(Clone)]
enum PendingAction {
    Content {
        category: String,
        token_symbol: Option<String>,
    },
}

// Глобальное состояние ожидающих чатов
type WaitingMap = Arc<Mutex<HashMap<ChatId, PendingAction>>>;

// Белый список пользователей
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

pub async fn start_bot() {
    let token: String = env::var("BOT_TOKEN").unwrap();
    let bot: Bot = Bot::new(token);
    let http_client = Client::new();
    let api_url =
        env::var("API_URL").unwrap_or_else(|_| "http://localhost:3001/api/add-content".to_string());
    let public_dir = PathBuf::from(
        env::var("PUBLIC_DIR").unwrap_or_else(|_| "../frontend/public/images".to_string()),
    );
    let public_dir = Arc::new(public_dir);
    let waiting: WaitingMap = Arc::new(Mutex::new(HashMap::new()));

    let handler = {
        let http_client = http_client.clone();
        let api_url = api_url.clone();
        let public_dir = public_dir.clone();
        let waiting = waiting.clone();

        Update::filter_message()
            .filter(|msg: Message| is_user_allowed(&msg.chat.id))
            .branch(dptree::endpoint(
                move |msg: Message, bot: Bot| {
                    let bot = bot.clone();
                    let http_client = http_client.clone();
                    let api_url = api_url.clone();
                    let public_dir = public_dir.clone();
                    let waiting = waiting.clone();

                    async move {
                        let chat_id = msg.chat.id;

                        // Проверяем, есть ли ожидающее действие
                        let pending = {
                            let lock = waiting.lock().unwrap();
                            lock.get(&chat_id).cloned()
                        };

                        if let Some(pending) = pending {
                            // Обрабатываем ожидаемое действие
                            match pending {
                                PendingAction::Content {
                                    category,
                                    token_symbol,
                                } => {
                                    let text = msg
                                        .text()
                                        .or(msg.caption())
                                        .unwrap_or_default()
                                        .to_string();
                                    let has_photo = msg.photo().is_some();

                                    if text.is_empty() && !has_photo {
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
                                                    match http_client.get(&file_url).send().await {
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
                                                                    // не сбрасываем ожидание, даём повторить
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

                                        match http_client
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

                                        // Сбрасываем ожидание после успешной обработки или ошибки API
                                        waiting.lock().unwrap().remove(&chat_id);
                                    }
                                }
                            }
                        } else {
                            // Нет ожидания – обрабатываем как команду
                            if let Some(text) = msg.text() {
                                if let Ok(cmd) = Command::parse(text, "allweb3jobs_bot") {
                                    match cmd {
                                        Command::Start | Command::Help => {
                                            bot.send_message(
                                                chat_id,
                                                "Choose a section:\n\
                                                /intern - Internships & Juniors\n\
                                                /mid - Mid/Senior roles\n\
                                                /news - News\n\
                                                /activity - Activities\n\
                                                /token SYMBOL - Token analysis\n\
                                                /cancel - Cancel current action",
                                            )
                                            .await?;
                                        }
                                        Command::Intern => {
                                            bot.send_message(
                                                chat_id,
                                                "Send text + optional photo for an Internship/Junior job",
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
                                        Command::Mid => {
                                            bot.send_message(
                                                chat_id,
                                                "Send text + optional photo for a Mid/Senior job",
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
                                        Command::News => {
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
                                        Command::Activity => {
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
                                        Command::Token(symbol) => {
                                            let symbol = symbol.to_uppercase();
                                            bot.send_message(
                                                chat_id,
                                                format!(
                                                    "Send text + optional photo for token ${}",
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
                                        Command::Cancel => {
                                            waiting.lock().unwrap().remove(&chat_id);
                                            bot.send_message(chat_id, "Cancelled").await?;
                                        }
                                    }
                                } else {
                                    bot.send_message(
                                        chat_id,
                                        "Use a command to select section, e.g. /intern",
                                    )
                                    .await?;
                                }
                            } else {
                                bot.send_message(
                                    chat_id,
                                    "Use a command to select section, e.g. /intern",
                                )
                                .await?;
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