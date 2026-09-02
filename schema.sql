-- ========================================================
-- SCHOOL MANAGEMENT SYSTEM - SUPABASE DATABASE SCHEMA
-- Copy and paste this script into your Supabase SQL Editor:
-- Dashboard -> SQL Editor -> New Query -> Run
-- ========================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TEACHERS TABLE
CREATE TABLE IF NOT EXISTS public.teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. DIVISIONS TABLE
CREATE TABLE IF NOT EXISTS public.divisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. SUBJECTS TABLE
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. STUDENTS TABLE
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    roll_number TEXT,
    avatar_url TEXT,
    division_id UUID REFERENCES public.divisions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. ATTENDANCE TABLE
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Present', 'Absent', 'Late')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. GRADES TABLE
CREATE TABLE IF NOT EXISTS public.grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
    exam_name TEXT NOT NULL,
    marks_obtained NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ========================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Enabling public read/write access for application usage
-- ========================================================
ALTER TABLE public.teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all access to teachers" ON public.teachers FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to divisions" ON public.divisions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to subjects" ON public.subjects FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to students" ON public.students FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to attendance" ON public.attendance FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all access to grades" ON public.grades FOR ALL USING (true) WITH CHECK (true);

-- ========================================================
-- STORAGE BUCKET FOR AVATARS
-- ========================================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('student-avatars', 'student-avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Read Access for Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'student-avatars');
CREATE POLICY "Public Insert Access for Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'student-avatars');
CREATE POLICY "Public Update Access for Avatars" ON storage.objects FOR UPDATE USING (bucket_id = 'student-avatars');
CREATE POLICY "Public Delete Access for Avatars" ON storage.objects FOR DELETE USING (bucket_id = 'student-avatars');

-- ========================================================
-- SAMPLE DEMO DATA (OPTIONAL)
-- ========================================================
INSERT INTO public.teachers (name, email) VALUES
('John Doe', 'john.doe@school.edu'),
('Sarah Smith', 'sarah.smith@school.edu')
ON CONFLICT DO NOTHING;
