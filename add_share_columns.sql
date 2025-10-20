-- Add share_code and is_shared columns to shopping_lists table if they don't exist

-- Add share_code column
ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS share_code TEXT;

-- Add is_shared column
ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT FALSE;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_shopping_lists_share_code 
ON shopping_lists(share_code) 
WHERE share_code IS NOT NULL;

-- Verify the changes
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'shopping_lists'
AND column_name IN ('share_code', 'is_shared');
