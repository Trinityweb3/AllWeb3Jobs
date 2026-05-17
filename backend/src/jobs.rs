use crate::models::{Job, Post};
use anyhow::Result;
use chrono::Utc;
use slug::slugify;
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;

pub const JOBS_DIR: &str = "../data/jobs";
pub const CONTENT_DIR: &str = "../data/content";

pub fn load_jobs() -> Result<Vec<Job>> {
    let mut jobs = Vec::new();
    let dir = PathBuf::from(JOBS_DIR);
    if !dir.exists() {
        fs::create_dir_all(&dir)?;
        return Ok(jobs);
    }
    for entry in fs::read_dir(&dir)? {
        let path = entry?.path();
        if path.extension().map_or(false, |ext| ext == "json") {
            let content = fs::read_to_string(&path)?;
            if let Ok(job) = serde_json::from_str::<Job>(&content) {
                jobs.push(job);
            }
        }
    }
    jobs.sort_by(|a, b| b.date.cmp(&a.date));
    Ok(jobs)
}

pub fn create_job(title: &str, description_full: &str, category: &str) -> Result<Job> {
    let now = Utc::now().to_rfc3339();
    let slug = format!(
        "{}-{}",
        slugify(title),
        Uuid::new_v4().to_string().split('-').next().unwrap()
    );
    let short = if description_full.len() > 200 {
        format!("{}...", &description_full[..200])
    } else {
        description_full.to_string()
    };
    let job = Job {
        slug: slug.clone(),
        title: title.to_string(),
        description_short: short,
        description_full: description_full.to_string(),
        date: now,
        category: category.to_string(),
        company: None,
        location: None,
        job_type: None,
    };
    let dir = PathBuf::from(JOBS_DIR);
    fs::create_dir_all(&dir)?;
    let file_path = dir.join(format!("{}.json", slug));
    fs::write(&file_path, serde_json::to_string_pretty(&job)?)?;
    Ok(job)
}

pub fn create_post(
    post_type: &str,
    title: &str,
    description: &str,
    category: &str,
    token_symbol: Option<String>,
    image_url: Option<String>,
    dir: &str,
) -> Result<String> {
    let slug = format!(
        "{}-{}",
        slugify(title),
        Uuid::new_v4().to_string().split('-').next().unwrap()
    );
    let now = Utc::now().to_rfc3339();
    let post = Post {
        slug: slug.clone(),
        title: title.to_string(),
        description: description.to_string(),
        date: now,
        category: category.to_string(),
        post_type: post_type.to_string(),
        token_symbol,
        image_url,
        company: None,
        location: None,
        job_type: None,
    };
    let dir_path = PathBuf::from(dir);
    fs::create_dir_all(&dir_path)?;
    let file_path = dir_path.join(format!("{}.json", slug));
    fs::write(file_path, serde_json::to_string_pretty(&post)?)?;
    Ok(slug)
}