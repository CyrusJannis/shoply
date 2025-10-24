-- ============================================
-- FIX: Add Missing Onboarding Columns to Users Table
-- Copy and run this in Supabase SQL Editor
-- ============================================

-- Add age column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS age INTEGER;

-- Add height column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS height DOUBLE PRECISION;

-- Add height_unit column (cm or ft)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS height_unit TEXT DEFAULT 'cm';

-- Add gender column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS gender TEXT;

-- diet_preferences already exists in your schema, but let's make sure it's JSONB
-- (Your schema already has this, so this is just a safety check)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'diet_preferences'
    ) THEN
        ALTER TABLE users ADD COLUMN diet_preferences JSONB DEFAULT '[]';
    END IF;
END $$;

-- ============================================
-- DONE! Now try the onboarding again
-- ============================================
