import Link from 'next/link';
import { Job } from '@/lib/jobs';

interface JobCardProps {
  job: Job;
}

export default function JobCard({ job }: JobCardProps) {
  const formatDate = (dateString: string) => {
    const d = new Date(dateString);
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  return (
    <Link href={`/jobs/${job.slug}`} className="block group">
      <article className="bg-white rounded-xl border border-gray-200 p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5 h-full flex flex-col">
        {/* Заголовок */}
        <h2 className="text-lg font-semibold text-gray-900 group-hover:text-brand-500 transition-colors mb-1">
          {job.title}
        </h2>

        {/* Дата публикации */}
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          <span>Posted on {formatDate(job.date)}</span>
        </div>

        {/* Локация и тип занятости (если есть) */}
        {(job.location || job.type) && (
          <div className="flex flex-wrap items-center gap-2 text-sm text-gray-500 mb-3">
            {job.location && (
              <span className="inline-flex items-center gap-1">
                <span>📍</span> {job.location}
              </span>
            )}
            {job.type && (
              <span className="px-2 py-0.5 bg-gray-100 rounded-full text-xs">
                {job.type}
              </span>
            )}
          </div>
        )}

        {/* Кнопка Read more */}
        <div className="mt-auto pt-3 border-t border-gray-100">
          <span className="text-brand-500 hover:text-brand-700 font-medium text-sm inline-flex items-center gap-1 transition-colors">
            Read more →
          </span>
        </div>
      </article>
    </Link>
  );
}