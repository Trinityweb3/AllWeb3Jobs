use crate::models::Job;
use anyhow::Result;
use chrono::Utc;
use slug::slugify;
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;

pub const JOBS_DIR: &str = "../data/jobs";

pub fn load_jobs() -> Result<Vec<Job>> {
    let mut jobs = Vec::new();
    let dir = PathBuf::from(JOBS_DIR);
    if !dir.exists() {
        fs::create_dir_all(&dir)?;
    }
    for entry in fs::read_dir(&dir)? {
        let path = entry?.path();
        if path.extension().map_or(false, |ext| ext == "json") {
            let content = fs::read_to_string(&path)?;
            let mut job: Job = serde_json::from_str(&content)?;
            if job.slug.is_empty() {
                job.slug = slugify(&job.title);
            }
            if job.description_short.is_empty() {
                job.description_short = job.description_full.chars().take(200).collect();
            }
            jobs.push(job);
        }
    }
    jobs.sort_by(|a, b| b.date.cmp(&a.date));
    Ok(jobs)
}

pub fn create_job(title: &str, description_full: &str, category: &str) -> Result<Job> {
    let now = Utc::now().to_rfc3339();
    let slug = format!("{}-{}", slugify(title), Uuid::new_v4().to_string().split('-').next().unwrap());
    let short = if description_full.len() > 200 {
        format!("{}...", &description_full[..200])
    } else {
        description_full.to_string()
    };
    let job = Job {
        slug,
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
    let file_path = dir.join(format!("{}.json", job.slug));
    fs::write(&file_path, serde_json::to_string_pretty(&job)?)?;
    Ok(job)
}
