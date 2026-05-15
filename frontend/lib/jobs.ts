import fs from 'fs/promises';
import path from 'path';
import { slugify } from './slugify';

export interface Job {
  slug: string;
  title: string;
  description_short: string;
  description_full: string;
  date: string;
  category: string;
  company?: string | null;
  location?: string | null;
  type?: string | null;
}

const jobsDirectory = path.join(process.cwd(), '..', 'data', 'jobs');

function validateJob(data: any): Job | null {
  if (typeof data.title !== 'string' || typeof data.description_full !== 'string') {
    console.warn('Skipping invalid job');
    return null;
  }
  const date = typeof data.date === 'string' ? data.date : new Date().toISOString();
  const category = typeof data.category === 'string' ? data.category : 'general';
  return {
    slug: '',
    title: data.title,
    description_short: data.description_short ?? data.description_full.slice(0, 200),
    description_full: data.description_full,
    date,
    category,
    company: data.company ?? null,
    location: data.location ?? null,
    type: data.type ?? null,
  };
}

export async function getAllJobs(): Promise<Job[]> {
  try {
    await fs.access(jobsDirectory);
  } catch {
    return [];
  }
  const fileNames = await fs.readdir(jobsDirectory);
  const jobs: Job[] = [];
  for (const fileName of fileNames) {
    if (!fileName.endsWith('.json')) continue;
    try {
      const fullPath = path.join(jobsDirectory, fileName);
      const content = await fs.readFile(fullPath, 'utf8');
      const raw = JSON.parse(content);
      const job = validateJob(raw);
      if (job) {
        const slug = slugify(job.title) || fileName.replace(/\.json$/, '');
        jobs.push({ ...job, slug,
          company: job.company ?? null,
          location: job.location ?? null,
          type: job.type ?? null,
        });
      }
    } catch (err) {
      console.error(`Error processing ${fileName}:`, err);
    }
  }
  return jobs.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getJobBySlug(slug: string): Promise<Job | null> {
  const all = await getAllJobs();
  return all.find(j => j.slug === slug) || null;
}

export async function getJobsByCategory(category: string): Promise<Job[]> {
  const all = await getAllJobs();
  return all.filter(j => j.category === category);
}

export async function getAllSlugs(): Promise<string[]> {
  const all = await getAllJobs();
  return all.map(j => j.slug);
}
