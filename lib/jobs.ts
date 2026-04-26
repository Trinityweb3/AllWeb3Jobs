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
  company?: string;
  location?: string;
  type?: string;
}

const jobsDirectory = path.join(process.cwd(), 'data/jobs');

function validateJob(data: any): Job | null {
  if (
    typeof data.title !== 'string' ||
    typeof data.description_full !== 'string'
  ) {
    console.warn(`Skipping invalid job: missing title or description_full`);
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
    company: data.company,
    location: data.location,
    type: data.type,
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
    const fileContents = await fs.readFile(fullPath, 'utf8');
    const raw = JSON.parse(fileContents);
    const job = validateJob(raw);
    if (job) {
      const slug = slugify(job.title) || fileName.replace(/\.json$/, '');
      const cleanJob = {
        ...job,
        slug,
        company: job.company ?? null,
        location: job.location ?? null,
        type: job.type ?? null,
      };
      jobs.push(cleanJob);
    }
  } catch (err) {
    console.error(`Error processing ${fileName}:`, err);
  }
}

  return jobs.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getJobBySlug(slug: string): Promise<Job | null> {
  const all = await getAllJobs();
  return all.find((j) => j.slug === slug) || null;
}

export async function getJobsByCategory(category: string): Promise<Job[]> {
  const all = await getAllJobs();
  return all.filter((j) => j.category === category);
}

export async function getAllSlugs(): Promise<string[]> {
  const all = await getAllJobs();
  return all.map((j) => j.slug);
}

export async function createJobFile(data: {
  title: string;
  description_full: string;
  category: string;
}): Promise<Job> {
  const date = new Date().toISOString();
  const slugBase = slugify(data.title);
  const slug = `${slugBase}-${Date.now()}`;
  const short =
    data.description_full.length > 200
      ? data.description_full.slice(0, 200) + '...'
      : data.description_full;

  const job: Job = {
    slug,
    title: data.title,
    description_short: short,
    description_full: data.description_full,
    date,
    category: data.category,
  };

  const filePath = path.join(jobsDirectory, `${slug}.json`);
  await fs.mkdir(jobsDirectory, { recursive: true });
  await fs.writeFile(filePath, JSON.stringify(job, null, 2), 'utf8');
  return job;
}
