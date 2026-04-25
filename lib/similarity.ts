import { Job } from './jobs';

export function getSimilarJobs(current: Job, allJobs: Job[], limit = 3): Job[] {
  const stopWords = new Set([
    'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'are',
    'we', 'you', 'they', 'it', 'with', 'as', 'by', 'from', 'that', 'this', 'be',
  ]);

  const getKeywords = (text: string): string[] =>
    text
      .toLowerCase()
      .split(/\W+/)
      .filter((w) => w.length > 2 && !stopWords.has(w));

  const currentKeywords = new Set([
    ...getKeywords(current.title),
    ...getKeywords(current.description_short),
  ]);

  return allJobs
    .filter((job) => job.slug !== current.slug)
    .map((job) => ({
      job,
      score: [...getKeywords(job.title), ...getKeywords(job.description_short)]
        .filter((w) => currentKeywords.has(w)).length,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((item) => item.job);
}
