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

-- ========================================================
-- PROFILES TABLE & AUTOMATIC USER SYNC
-- ========================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    role TEXT NOT NULL DEFAULT 'pending' CHECK (role IN ('pending', 'admin', 'teacher', 'student', 'parent')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for Profiles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view their own profile'
    ) THEN
        CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update their own profile'
    ) THEN
        CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can insert their own profile'
    ) THEN
        CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- Automatic Profile Creation Trigger on Auth Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.email,
    'pending',
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger execution
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========================================================
-- SECURITY HARDENING & RPC ROLE ASSIGNMENT
-- ========================================================

-- 1. Prevent users from modifying their own role via direct UPDATE
CREATE OR REPLACE FUNCTION public.prevent_profile_role_self_update()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    IF auth.uid() IS NOT NULL THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
      ) THEN
        RAISE EXCEPTION 'Access denied: Only administrators can update user roles.';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP TRIGGER IF EXISTS tr_prevent_profile_role_self_update ON public.profiles;
CREATE TRIGGER tr_prevent_profile_role_self_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_self_update();

-- 2. Allow Admins to View All Profiles (Users can view own profile)
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins and users view profiles" ON public.profiles;

CREATE POLICY "Admins and users view profiles" ON public.profiles
FOR SELECT USING (
  auth.uid() = id 
  OR 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 3. Secure RPC function for Admin Role Assignment
CREATE OR REPLACE FUNCTION public.assign_user_role(target_user_id UUID, new_role TEXT)
RETURNS void AS $$
DECLARE
  caller_role TEXT;
BEGIN
  -- Verify caller is an authenticated admin
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role IS NULL OR caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Only active administrators can assign user roles.';
  END IF;

  -- Validate target role
  IF new_role NOT IN ('pending', 'admin', 'teacher', 'student', 'parent') THEN
    RAISE EXCEPTION 'Invalid role specified: %', new_role;
  END IF;

  -- Update target profile role
  UPDATE public.profiles
  SET role = new_role
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found for id: %', target_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

GRANT EXECUTE ON FUNCTION public.assign_user_role(UUID, TEXT) TO authenticated;


