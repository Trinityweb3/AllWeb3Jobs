import Head from 'next/head';
import Link from 'next/link';
import { siteConfig } from '@/lib/siteConfig';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  description?: string;
}

export default function Layout({ children, title, description }: LayoutProps) {
  const pageTitle = title || siteConfig.defaultTitle;
  const pageDesc = description || siteConfig.defaultDescription;

  return (
    <>
      <Head>
        <title>{pageTitle}</title>
        <meta name="description" content={pageDesc} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="min-h-screen bg-gray-50">
        <header className="bg-white shadow-sm border-b">
          <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            <Link href="/" className="text-xl font-bold text-gray-900">
              {siteConfig.name}
            </Link>
            <div className="flex gap-4">
              <Link href="/" className="text-gray-600 hover:text-gray-900">All Jobs</Link>
              <Link href="/category/internships-juniors" className="text-gray-600 hover:text-gray-900">Internships</Link>
              <Link href="/category/mid-senior-leads" className="text-gray-600 hover:text-gray-900">Mid & Senior</Link>
            </div>
          </nav>
        </header>
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </main>
        <footer className="bg-white border-t mt-12 py-6 text-center text-gray-500 text-sm">
          © {new Date().getFullYear()} {siteConfig.name}
        </footer>
      </div>
    </>
  );
}
