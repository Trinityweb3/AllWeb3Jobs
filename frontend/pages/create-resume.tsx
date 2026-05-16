import { useState, useRef, useCallback } from 'react';
import Head from 'next/head';
import Layout from '@/components/Layout';
import ResumePreview from '@/components/ResumePreview';
import { useReactToPrint } from 'react-to-print';

export interface ResumeData {
  template: 'modern' | 'classic' | 'minimal';
  personal: {
    fullName: string;
    title: string;
    email: string;
    phone: string;
    location: string;
    website: string;
    summary: string;
  };
  experience: {
    id: string;
    company: string;
    position: string;
    startDate: string;
    endDate: string;
    description: string;
  }[];
  education: {
    id: string;
    school: string;
    degree: string;
    graduationYear: string;
  }[];
  skills: string[];
}

const emptyResume: ResumeData = {
  template: 'modern',
  personal: {
    fullName: '',
    title: '',
    email: '',
    phone: '',
    location: '',
    website: '',
    summary: '',
  },
  experience: [],
  education: [],
  skills: [],
};

export default function CreateResumePage() {
  const [resumeData, setResumeData] = useState<ResumeData>(emptyResume);
  const previewRef = useRef<HTMLDivElement>(null);

  const handlePrint = useReactToPrint({
    contentRef: previewRef,
    documentTitle: `${resumeData.personal.fullName || 'resume'}_CV`,
  });

  const updatePersonal = (field: string, value: string) => {
    setResumeData((prev) => ({
      ...prev,
      personal: { ...prev.personal, [field]: value },
    }));
  };

  const addExperience = () => {
    const newExp = {
      id: Date.now().toString(),
      company: '',
      position: '',
      startDate: '',
      endDate: '',
      description: '',
    };
    setResumeData((prev) => ({
      ...prev,
      experience: [...prev.experience, newExp],
    }));
  };

  const updateExperience = (id: string, field: string, value: string) => {
    setResumeData((prev) => ({
      ...prev,
      experience: prev.experience.map((exp) =>
        exp.id === id ? { ...exp, [field]: value } : exp
      ),
    }));
  };

  const removeExperience = (id: string) => {
    setResumeData((prev) => ({
      ...prev,
      experience: prev.experience.filter((exp) => exp.id !== id),
    }));
  };

  const addEducation = () => {
    const newEdu = {
      id: Date.now().toString(),
      school: '',
      degree: '',
      graduationYear: '',
    };
    setResumeData((prev) => ({
      ...prev,
      education: [...prev.education, newEdu],
    }));
  };

  const updateEducation = (id: string, field: string, value: string) => {
    setResumeData((prev) => ({
      ...prev,
      education: prev.education.map((edu) =>
        edu.id === id ? { ...edu, [field]: value } : edu
      ),
    }));
  };

  const removeEducation = (id: string) => {
    setResumeData((prev) => ({
      ...prev,
      education: prev.education.filter((edu) => edu.id !== id),
    }));
  };

  const updateSkills = (skillsString: string) => {
    const skillsArray = skillsString.split(',').map((s) => s.trim());
    setResumeData((prev) => ({ ...prev, skills: skillsArray }));
  };

  const changeTemplate = (template: 'modern' | 'classic' | 'minimal') => {
    setResumeData((prev) => ({ ...prev, template }));
  };

  return (
    <Layout title="Create Resume | AllWeb3Jobs">
      <Head>
        <style>{`
          @media print {
            body * { visibility: hidden; }
            #resume-preview, #resume-preview * { visibility: visible; }
            #resume-preview { position: absolute; left: 0; top: 0; width: 100%; }
          }
        `}</style>
      </Head>

      <div className="flex flex-col lg:flex-row gap-6 max-w-7xl mx-auto">
        <div className="w-full lg:w-1/2 bg-white p-6 rounded-xl border overflow-y-auto max-h-[90vh]">
          <h1 className="text-2xl font-bold mb-6">Create Your Resume</h1>

          <section className="mb-8">
            <h2 className="text-lg font-semibold mb-3">Template</h2>
            <div className="flex gap-3">
              {(['modern', 'classic', 'minimal'] as const).map((t) => (
                <button
                  key={t}
                  onClick={() => changeTemplate(t)}
                  className={`px-4 py-2 rounded-lg text-sm font-medium capitalize ${
                    resumeData.template === t
                      ? 'bg-brand-500 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  {t}
                </button>
              ))}
            </div>
          </section>

          <section className="mb-8">
            <h2 className="text-lg font-semibold mb-3">Personal Details</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {[
                ['fullName', 'Full Name'],
                ['title', 'Professional Title'],
                ['email', 'Email'],
                ['phone', 'Phone'],
                ['location', 'Location'],
                ['website', 'Website/Portfolio'],
              ].map(([field, label]) => (
                <input
                  key={field}
                  type="text"
                  placeholder={label}
                  value={(resumeData.personal as any)[field]}
                  onChange={(e) => updatePersonal(field, e.target.value)}
                  className="border rounded-lg px-3 py-2 text-sm"
                />
              ))}
            </div>
            <textarea
              placeholder="Professional summary"
              value={resumeData.personal.summary}
              onChange={(e) => updatePersonal('summary', e.target.value)}
              className="border rounded-lg px-3 py-2 text-sm w-full mt-3 h-24"
            />
          </section>

          <section className="mb-8">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-lg font-semibold">Experience</h2>
              <button onClick={addExperience} className="text-brand-500 text-sm font-medium hover:underline">
                + Add
              </button>
            </div>
            {resumeData.experience.map((exp) => (
              <div key={exp.id} className="border rounded-lg p-3 mb-3 relative">
                <button
                  onClick={() => removeExperience(exp.id)}
                  className="absolute top-2 right-2 text-red-400 hover:text-red-600"
                >
                  ✕
                </button>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <input
                    placeholder="Company"
                    value={exp.company}
                    onChange={(e) => updateExperience(exp.id, 'company', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                  <input
                    placeholder="Position"
                    value={exp.position}
                    onChange={(e) => updateExperience(exp.id, 'position', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                  <input
                    type="month"
                    placeholder="Start date"
                    value={exp.startDate}
                    onChange={(e) => updateExperience(exp.id, 'startDate', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                  <input
                    type="month"
                    placeholder="End date"
                    value={exp.endDate}
                    onChange={(e) => updateExperience(exp.id, 'endDate', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                </div>
                <textarea
                  placeholder="Description"
                  value={exp.description}
                  onChange={(e) => updateExperience(exp.id, 'description', e.target.value)}
                  className="border rounded px-2 py-1 text-sm w-full mt-2 h-20"
                />
              </div>
            ))}
          </section>

          <section className="mb-8">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-lg font-semibold">Education</h2>
              <button onClick={addEducation} className="text-brand-500 text-sm font-medium hover:underline">
                + Add
              </button>
            </div>
            {resumeData.education.map((edu) => (
              <div key={edu.id} className="border rounded-lg p-3 mb-3 relative">
                <button
                  onClick={() => removeEducation(edu.id)}
                  className="absolute top-2 right-2 text-red-400 hover:text-red-600"
                >
                  ✕
                </button>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <input
                    placeholder="School"
                    value={edu.school}
                    onChange={(e) => updateEducation(edu.id, 'school', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                  <input
                    placeholder="Degree"
                    value={edu.degree}
                    onChange={(e) => updateEducation(edu.id, 'degree', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                  <input
                    placeholder="Graduation year"
                    value={edu.graduationYear}
                    onChange={(e) => updateEducation(edu.id, 'graduationYear', e.target.value)}
                    className="border rounded px-2 py-1 text-sm"
                  />
                </div>
              </div>
            ))}
          </section>

          <section className="mb-8">
            <h2 className="text-lg font-semibold mb-3">Skills</h2>
            <input
              type="text"
              placeholder="e.g. Design, Solidity, React"
              value={resumeData.skills.join(', ')}
              onChange={(e) => updateSkills(e.target.value)}
              className="border rounded-lg px-3 py-2 text-sm w-full"
            />
          </section>

          <button
            onClick={handlePrint}
            className="w-full bg-brand-500 text-white py-3 rounded-lg font-medium hover:bg-brand-700 transition mt-4"
          >
            Export to PDF
          </button>
        </div>

        <div className="w-full lg:w-1/2 bg-gray-50 p-6 rounded-xl border overflow-y-auto max-h-[90vh]">
          <h2 className="text-lg font-semibold mb-4 text-gray-700">Preview</h2>
          <div className="bg-white shadow-lg mx-auto" style={{ maxWidth: '210mm' }}>
            <ResumePreview ref={previewRef} data={resumeData} />
          </div>
        </div>
      </div>
    </Layout>
  );
}