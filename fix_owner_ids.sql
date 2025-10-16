-- Fix Owner IDs Script
-- This script updates all shopping lists to be owned by the currently authenticated user
-- Run this in your Supabase SQL Editor

-- Step 1: Get your current user ID (you'll need to replace this with your actual ID)
-- You can find your user ID in the app's home screen or by running:
-- SELECT auth.uid();

-- Step 2: Update all shopping_lists to be owned by you
-- Replace 'YOUR_USER_ID_HERE' with your actual user ID from the app
UPDATE shopping_lists
SET owner_id = 'YOUR_USER_ID_HERE'
WHERE owner_id != 'YOUR_USER_ID_HERE';

-- Step 3: Update list_members to reflect the correct ownership
-- First, delete any existing memberships
DELETE FROM list_members
WHERE user_id != 'YOUR_USER_ID_HERE';

-- Then, ensure you are a member/owner of all your lists
INSERT INTO list_members (list_id, user_id, role)
SELECT id, 'YOUR_USER_ID_HERE', 'owner'
FROM shopping_lists
WHERE owner_id = 'YOUR_USER_ID_HERE'
ON CONFLICT (list_id, user_id) DO NOTHING;

-- Verify the changes
SELECT 
  sl.id,
  sl.name,
  sl.owner_id,
  COUNT(lm.id) as member_count
FROM shopping_lists sl
LEFT JOIN list_members lm ON sl.id = lm.list_id
GROUP BY sl.id, sl.name, sl.owner_id;
