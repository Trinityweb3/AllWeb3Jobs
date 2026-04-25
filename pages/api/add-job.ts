import type { NextApiRequest, NextApiResponse } from 'next';
import { createJobFile } from '@/lib/jobs';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const token = req.headers['x-bot-token'] || req.query.token;
  if (token !== process.env.BOT_API_SECRET) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  try {
    const { text, category } = req.body;

    if (!text || typeof text !== 'string' || !category || typeof category !== 'string') {
      return res.status(400).json({ error: 'Missing text or category' });
    }

    const lines = text.trim().split('\n');
    const title = lines[0].trim();
    const description_full = lines.slice(1).join('\n').trim() || title;

    if (!title) {
      return res.status(400).json({ error: 'Empty title' });
    }

    const allowedCategories = ['internships-juniors', 'mid-senior-leads'];
    if (!allowedCategories.includes(category)) {
      return res.status(400).json({ error: 'Invalid category' });
    }

    const job = await createJobFile({ title, description_full, category });

    await res.revalidate('/');
    await res.revalidate(`/category/${category}`);

    return res.status(201).json({ success: true, slug: job.slug });
  } catch (err) {
    console.error('Failed to add job', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
