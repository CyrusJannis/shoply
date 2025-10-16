-- Automatic Fix Owner IDs Script
-- This script automatically uses your current authenticated user ID
-- Run this in your Supabase SQL Editor while logged in

-- Update all shopping_lists to be owned by the currently authenticated user
UPDATE shopping_lists
SET owner_id = auth.uid()
WHERE owner_id != auth.uid();

-- Clean up list_members - remove memberships for other users
DELETE FROM list_members
WHERE user_id != auth.uid();

-- Ensure you are a member/owner of all your lists
INSERT INTO list_members (list_id, user_id, role)
SELECT id, auth.uid(), 'owner'
FROM shopping_lists
WHERE owner_id = auth.uid()
ON CONFLICT (list_id, user_id) DO NOTHING;

-- Verify the changes
SELECT 
  sl.id,
  sl.name,
  sl.owner_id,
  (sl.owner_id = auth.uid()) as is_mine,
  COUNT(lm.id) as member_count
FROM shopping_lists sl
LEFT JOIN list_members lm ON sl.id = lm.list_id
GROUP BY sl.id, sl.name, sl.owner_id;
