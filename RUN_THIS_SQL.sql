-- ============================================
-- SHOPLY DATABASE MIGRATIONS
-- Copy this ENTIRE file and paste into Supabase SQL Editor
-- Then click "RUN" - takes 10 seconds
-- ============================================

-- ============================================
-- MIGRATION 1: Purchase Tracking Table
-- ============================================

CREATE TABLE IF NOT EXISTS item_purchase_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  item_name TEXT NOT NULL,
  purchase_count INTEGER DEFAULT 1,
  first_purchase TIMESTAMP NOT NULL,
  last_purchase TIMESTAMP NOT NULL,
  purchase_dates TIMESTAMP[] DEFAULT '{}',
  average_days_between DOUBLE PRECISION,
  preferred_category TEXT,
  preferred_quantity DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, item_name)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_purchase_stats_user 
ON item_purchase_stats(user_id);

CREATE INDEX IF NOT EXISTS idx_purchase_stats_last_purchase 
ON item_purchase_stats(last_purchase DESC);

-- Enable Row Level Security
ALTER TABLE item_purchase_stats ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view own purchase stats" ON item_purchase_stats;
CREATE POLICY "Users can view own purchase stats"
ON item_purchase_stats FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own purchase stats" ON item_purchase_stats;
CREATE POLICY "Users can insert own purchase stats"
ON item_purchase_stats FOR INSERT 
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own purchase stats" ON item_purchase_stats;
CREATE POLICY "Users can update own purchase stats"
ON item_purchase_stats FOR UPDATE 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own purchase stats" ON item_purchase_stats;
CREATE POLICY "Users can delete own purchase stats"
ON item_purchase_stats FOR DELETE 
USING (auth.uid() = user_id);

-- ============================================
-- MIGRATION 2: Last Accessed Column
-- ============================================

-- Add last_accessed_at column to shopping_lists
ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_lists_last_accessed 
ON shopping_lists(owner_id, last_accessed_at DESC NULLS LAST);

-- Initialize with current updated_at values
UPDATE shopping_lists 
SET last_accessed_at = updated_at 
WHERE last_accessed_at IS NULL;

-- ============================================
-- MIGRATION 3: Recommendation Helper Function
-- ============================================

-- Drop function if exists (to allow recreation)
DROP FUNCTION IF EXISTS get_recommended_items(UUID, INTEGER);

-- Create recommendation function
CREATE OR REPLACE FUNCTION get_recommended_items(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 8
)
RETURNS TABLE (
  item_name TEXT,
  score DOUBLE PRECISION,
  reason TEXT,
  category TEXT,
  quantity DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ips.item_name,
    -- Calculate score based on frequency and recency
    (ips.purchase_count::DOUBLE PRECISION * 10) + 
    (CASE 
      WHEN ips.average_days_between IS NOT NULL AND 
           EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 > ips.average_days_between 
      THEN 50 
      ELSE 0 
    END) as score,
    -- Generate reason text
    CASE 
      WHEN ips.average_days_between IS NOT NULL AND 
           EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 > ips.average_days_between * 1.2
      THEN 'Overdue'
      WHEN ips.average_days_between IS NOT NULL
      THEN 'Usually buy every ' || ROUND(ips.average_days_between::NUMERIC, 0) || ' days'
      ELSE 'You buy this often'
    END as reason,
    ips.preferred_category,
    ips.preferred_quantity
  FROM item_purchase_stats ips
  WHERE ips.user_id = p_user_id
    AND ips.purchase_count >= 2  -- Only recommend items bought at least twice
    AND EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 < 90  -- Only items purchased in last 90 days
  ORDER BY score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_recommended_items(UUID, INTEGER) TO authenticated;

-- ============================================
-- VERIFICATION QUERIES (Optional - run to verify)
-- ============================================

-- Check if table exists
-- SELECT EXISTS (
--   SELECT FROM information_schema.tables 
--   WHERE table_name = 'item_purchase_stats'
-- );

-- Check if column exists
-- SELECT EXISTS (
--   SELECT FROM information_schema.columns 
--   WHERE table_name = 'shopping_lists' 
--   AND column_name = 'last_accessed_at'
-- );

-- Check if function exists
-- SELECT EXISTS (
--   SELECT FROM pg_proc 
--   WHERE proname = 'get_recommended_items'
-- );

-- ============================================
-- DONE! 
-- Your database is now ready for smart recommendations!
-- ============================================
