-- Database Migrations for Smart Shopping Features
-- Run these migrations in your Supabase SQL editor

-- ============================================
-- Migration 1: Purchase Tracking System
-- ============================================

-- Create item_purchase_stats table
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

CREATE INDEX IF NOT EXISTS idx_purchase_stats_count 
ON item_purchase_stats(purchase_count DESC);

CREATE INDEX IF NOT EXISTS idx_purchase_stats_user_name 
ON item_purchase_stats(user_id, item_name);

-- Enable Row Level Security
ALTER TABLE item_purchase_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own purchase stats"
ON item_purchase_stats FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own purchase stats"
ON item_purchase_stats FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own purchase stats"
ON item_purchase_stats FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own purchase stats"
ON item_purchase_stats FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- Migration 2: Last Accessed List Tracking
-- ============================================

-- Add last_accessed_at column to shopping_lists
ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_lists_last_accessed 
ON shopping_lists(user_id, last_accessed_at DESC NULLS LAST);

-- Initialize existing lists with current timestamp
UPDATE shopping_lists 
SET last_accessed_at = updated_at 
WHERE last_accessed_at IS NULL;

-- ============================================
-- Migration 3: Auto-update Triggers
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for item_purchase_stats
DROP TRIGGER IF EXISTS update_purchase_stats_updated_at ON item_purchase_stats;
CREATE TRIGGER update_purchase_stats_updated_at
BEFORE UPDATE ON item_purchase_stats
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Migration 4: Helper Functions
-- ============================================

-- Function to calculate average days between purchases
CREATE OR REPLACE FUNCTION calculate_average_days(purchase_dates TIMESTAMP[])
RETURNS DOUBLE PRECISION AS $$
DECLARE
  total_days DOUBLE PRECISION := 0;
  date_count INTEGER;
  i INTEGER;
BEGIN
  date_count := array_length(purchase_dates, 1);
  
  IF date_count IS NULL OR date_count < 2 THEN
    RETURN NULL;
  END IF;
  
  FOR i IN 2..date_count LOOP
    total_days := total_days + EXTRACT(EPOCH FROM (purchase_dates[i] - purchase_dates[i-1])) / 86400;
  END LOOP;
  
  RETURN total_days / (date_count - 1);
END;
$$ LANGUAGE plpgsql;

-- Function to get recommended items for a user
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
    -- Simple scoring: frequency * recency factor
    (ips.purchase_count::DOUBLE PRECISION * 10) + 
    (CASE 
      WHEN ips.average_days_between IS NOT NULL AND 
           EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 > ips.average_days_between 
      THEN 50 
      ELSE 0 
    END) as score,
    CASE 
      WHEN ips.average_days_between IS NOT NULL AND 
           EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 > ips.average_days_between * 1.2
      THEN 'Overdue by ' || ROUND((EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 - ips.average_days_between)::NUMERIC, 0) || ' days'
      WHEN ips.average_days_between IS NOT NULL
      THEN 'Usually buy every ' || ROUND(ips.average_days_between::NUMERIC, 0) || ' days'
      ELSE 'You buy this often (' || ips.purchase_count || 'x)'
    END as reason,
    ips.preferred_category,
    ips.preferred_quantity
  FROM item_purchase_stats ips
  WHERE ips.user_id = p_user_id
    AND ips.purchase_count >= 2
    AND EXTRACT(EPOCH FROM (NOW() - ips.last_purchase)) / 86400 < 90 -- Not too old
  ORDER BY score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Migration 5: Data Cleanup Functions
-- ============================================

-- Function to clean up old purchase stats
CREATE OR REPLACE FUNCTION cleanup_old_purchase_stats()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM item_purchase_stats
  WHERE last_purchase < NOW() - INTERVAL '1 year'
    AND purchase_count < 3;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Verification Queries
-- ============================================

-- Check if tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('item_purchase_stats', 'shopping_lists')
ORDER BY table_name;

-- Check indexes
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('item_purchase_stats', 'shopping_lists')
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'item_purchase_stats'
ORDER BY tablename, policyname;

-- ============================================
-- Test Data (Optional - for development)
-- ============================================

-- Insert sample purchase stats (replace with your user_id)
/*
INSERT INTO item_purchase_stats (
  user_id,
  item_name,
  purchase_count,
  first_purchase,
  last_purchase,
  purchase_dates,
  average_days_between,
  preferred_category,
  preferred_quantity
) VALUES (
  'YOUR_USER_ID_HERE',
  'Milk',
  12,
  NOW() - INTERVAL '84 days',
  NOW() - INTERVAL '8 days',
  ARRAY[
    NOW() - INTERVAL '84 days',
    NOW() - INTERVAL '77 days',
    NOW() - INTERVAL '70 days',
    NOW() - INTERVAL '63 days',
    NOW() - INTERVAL '56 days',
    NOW() - INTERVAL '49 days',
    NOW() - INTERVAL '42 days',
    NOW() - INTERVAL '35 days',
    NOW() - INTERVAL '28 days',
    NOW() - INTERVAL '21 days',
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '8 days'
  ],
  7.0,
  'Kühlprodukte',
  1.0
);
*/

-- ============================================
-- Rollback Script (if needed)
-- ============================================

/*
-- Drop functions
DROP FUNCTION IF EXISTS get_recommended_items(UUID, INTEGER);
DROP FUNCTION IF EXISTS cleanup_old_purchase_stats();
DROP FUNCTION IF EXISTS calculate_average_days(TIMESTAMP[]);

-- Drop triggers
DROP TRIGGER IF EXISTS update_purchase_stats_updated_at ON item_purchase_stats;

-- Drop table
DROP TABLE IF EXISTS item_purchase_stats CASCADE;

-- Remove column
ALTER TABLE shopping_lists DROP COLUMN IF EXISTS last_accessed_at;
*/
