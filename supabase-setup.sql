-- Swift Update Notifier - Supabase Setup
-- Copy and paste this code into your Supabase SQL Editor

-- Önce tabloyu siliyoruz (eğer varsa)
DROP TABLE IF EXISTS public.appversions;

-- Create the appversions table
CREATE TABLE public.appversions (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    version text NOT NULL,
    update_message text NOT NULL,
    is_critical boolean DEFAULT false,
    version_date timestamp with time zone DEFAULT now(),
    app_store_url text NOT NULL
);

-- Add comment on the table
COMMENT ON TABLE public.appversions IS 'Stores information about different app versions';

-- Add comments on the columns
COMMENT ON COLUMN public.appversions.id IS 'Unique identifier for the app version';
COMMENT ON COLUMN public.appversions.version IS 'Version number in semver format (e.g., 1.2.3)';
COMMENT ON COLUMN public.appversions.update_message IS 'Message to display to users about the update';
COMMENT ON COLUMN public.appversions.is_critical IS 'Whether this update is critical and users should be forced to update';
COMMENT ON COLUMN public.appversions.version_date IS 'When this version was released';
COMMENT ON COLUMN public.appversions.app_store_url IS 'URL to the app in the App Store';

-- Set up RLS policies to allow anonymous users to read
ALTER TABLE public.appversions ENABLE ROW LEVEL SECURITY;

-- Anyone can read app versions (including anonymous users)
CREATE POLICY "Anyone can read app versions" ON public.appversions
    FOR SELECT USING (true);

-- Only admins can insert/update/delete app versions
-- ⚠️ Change 'admin@example.com' to your actual admin email
CREATE POLICY "Only admins can insert app versions" ON public.appversions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

CREATE POLICY "Only admins can update app versions" ON public.appversions
    FOR UPDATE USING (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

CREATE POLICY "Only admins can delete app versions" ON public.appversions
    FOR DELETE USING (auth.role() = 'authenticated' AND auth.email() = 'admin@example.com');

-- Insert some sample data with higher version than 1.0.0
-- ⚠️ Replace the app store URL with your actual app URL
INSERT INTO public.appversions (version, update_message, is_critical, app_store_url)
VALUES 
    ('1.1.0', 'new features added: Version tracking and automatic update notifications.', false, 'https://apps.apple.com/app/your-app/id123456789'),