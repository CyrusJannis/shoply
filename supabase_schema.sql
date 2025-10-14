-- Shoply Database Schema for Supabase/PostgreSQL
-- Run this script in your Supabase SQL Editor to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  auth_provider TEXT, -- 'google', 'apple', 'email'
  diet_preferences JSONB DEFAULT '[]', -- ['vegan', 'gluten_free', etc.]
  notification_enabled BOOLEAN DEFAULT true,
  language TEXT DEFAULT 'de',
  theme TEXT DEFAULT 'light', -- 'light', 'dark', 'system'
  fcm_token TEXT, -- Firebase Cloud Messaging token
  onboarding_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP
);

-- ============================================================================
-- SHOPPING LISTS TABLE
-- ============================================================================
CREATE TABLE shopping_lists (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
  share_code TEXT UNIQUE, -- 6-digit code
  qr_code_data TEXT, -- QR code as Base64
  share_link TEXT UNIQUE,
  is_shared BOOLEAN DEFAULT false,
  sort_mode TEXT DEFAULT 'category', -- 'category', 'quantity', 'manual', 'alphabetical'
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- LIST MEMBERS TABLE
-- ============================================================================
CREATE TABLE list_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'owner', 'member'
  joined_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(list_id, user_id)
);

-- ============================================================================
-- SHOPPING ITEMS TABLE
-- ============================================================================
CREATE TABLE shopping_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity REAL DEFAULT 1,
  unit TEXT, -- 'kg', 'L', 'pieces', etc.
  category TEXT, -- 'Fruits & Vegetables', 'Meat & Fish', 'Dairy', etc.
  notes TEXT,
  is_checked BOOLEAN DEFAULT false,
  is_diet_warning BOOLEAN DEFAULT false, -- Orange marking when not matching diet
  barcode TEXT,
  added_by UUID REFERENCES users(id),
  sort_order INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  checked_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- SHOPPING HISTORY TABLE
-- ============================================================================
CREATE TABLE shopping_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  list_id UUID REFERENCES shopping_lists(id) ON DELETE SET NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  items JSONB NOT NULL, -- Snapshot of all items at completion
  total_items INTEGER,
  completed_at TIMESTAMP DEFAULT NOW(),
  list_name TEXT
);

-- ============================================================================
-- PURCHASE FREQUENCY TABLE
-- ============================================================================
CREATE TABLE purchase_frequency (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  category TEXT,
  purchase_count INTEGER DEFAULT 1,
  last_purchased TIMESTAMP DEFAULT NOW(),
  avg_days_between_purchases REAL,
  UNIQUE(user_id, item_name)
);

-- ============================================================================
-- RECIPES TABLE
-- ============================================================================
CREATE TABLE recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  prep_time INTEGER, -- Minutes
  cook_time INTEGER,
  servings INTEGER DEFAULT 4,
  difficulty TEXT, -- 'easy', 'medium', 'hard'
  diet_tags JSONB DEFAULT '[]', -- ['vegan', 'gluten_free', 'low_carb', etc.]
  ingredients JSONB NOT NULL, -- [{"name": "Flour", "quantity": 200, "unit": "g"}, ...]
  instructions JSONB NOT NULL, -- [{"step": 1, "text": "..."}, ...]
  nutrition JSONB, -- {"calories": 250, "protein": 12, "carbs": 30, "fat": 8}
  source_type TEXT, -- 'internal', 'external', 'user'
  source_url TEXT, -- if external
  created_by UUID REFERENCES users(id),
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- FAVORITE RECIPES TABLE
-- ============================================================================
CREATE TABLE favorite_recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, recipe_id)
);

-- ============================================================================
-- PROMOTIONAL FLYERS TABLE
-- ============================================================================
CREATE TABLE promotional_flyers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  supermarket_name TEXT NOT NULL,
  supermarket_logo TEXT,
  title TEXT NOT NULL,
  valid_from DATE,
  valid_until DATE,
  pages JSONB NOT NULL, -- [{"page": 1, "image_url": "..."}, ...]
  pdf_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT NOT NULL, -- 'item_added', 'item_checked', 'list_shared', 'recommendation'
  related_list_id UUID REFERENCES shopping_lists(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================
CREATE INDEX idx_shopping_items_list_id ON shopping_items(list_id);
CREATE INDEX idx_list_members_user_id ON list_members(user_id);
CREATE INDEX idx_list_members_list_id ON list_members(list_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_shopping_history_user_id ON shopping_history(user_id);
CREATE INDEX idx_purchase_frequency_user_id ON purchase_frequency(user_id);
CREATE INDEX idx_favorite_recipes_user_id ON favorite_recipes(user_id);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE list_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_frequency ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotional_flyers ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own data" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own data" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Shopping Lists policies
CREATE POLICY "Members can view lists" ON shopping_lists FOR SELECT 
  USING (
    owner_id = auth.uid() OR 
    id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Owners can insert lists" ON shopping_lists FOR INSERT 
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owners can update lists" ON shopping_lists FOR UPDATE 
  USING (owner_id = auth.uid());

CREATE POLICY "Owners can delete lists" ON shopping_lists FOR DELETE 
  USING (owner_id = auth.uid());

-- List Members policies
CREATE POLICY "Members can view list members" ON list_members FOR SELECT 
  USING (
    list_id IN (
      SELECT id FROM shopping_lists WHERE 
        owner_id = auth.uid() OR 
        id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Owners can add members" ON list_members FOR INSERT 
  WITH CHECK (
    list_id IN (SELECT id FROM shopping_lists WHERE owner_id = auth.uid())
  );

CREATE POLICY "Users can remove themselves" ON list_members FOR DELETE 
  USING (user_id = auth.uid());

CREATE POLICY "Owners can remove members" ON list_members FOR DELETE 
  USING (
    list_id IN (SELECT id FROM shopping_lists WHERE owner_id = auth.uid())
  );

-- Shopping Items policies
CREATE POLICY "Members can view items" ON shopping_items FOR SELECT 
  USING (
    list_id IN (
      SELECT id FROM shopping_lists WHERE 
        owner_id = auth.uid() OR 
        id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can add items" ON shopping_items FOR INSERT 
  WITH CHECK (
    list_id IN (
      SELECT id FROM shopping_lists WHERE 
        owner_id = auth.uid() OR 
        id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can update items" ON shopping_items FOR UPDATE 
  USING (
    list_id IN (
      SELECT id FROM shopping_lists WHERE 
        owner_id = auth.uid() OR 
        id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
    )
  );

CREATE POLICY "Members can delete items" ON shopping_items FOR DELETE 
  USING (
    list_id IN (
      SELECT id FROM shopping_lists WHERE 
        owner_id = auth.uid() OR 
        id IN (SELECT list_id FROM list_members WHERE user_id = auth.uid())
    )
  );

-- Shopping History policies
CREATE POLICY "Users can view own history" ON shopping_history FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own history" ON shopping_history FOR INSERT WITH CHECK (user_id = auth.uid());

-- Purchase Frequency policies
CREATE POLICY "Users can view own frequency" ON purchase_frequency FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own frequency" ON purchase_frequency FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own frequency" ON purchase_frequency FOR UPDATE USING (user_id = auth.uid());

-- Recipes policies
CREATE POLICY "Everyone can view public recipes" ON recipes FOR SELECT USING (is_public = true OR created_by = auth.uid());
CREATE POLICY "Users can insert recipes" ON recipes FOR INSERT WITH CHECK (created_by = auth.uid());
CREATE POLICY "Users can update own recipes" ON recipes FOR UPDATE USING (created_by = auth.uid());
CREATE POLICY "Users can delete own recipes" ON recipes FOR DELETE USING (created_by = auth.uid());

-- Favorite Recipes policies
CREATE POLICY "Users can view own favorites" ON favorite_recipes FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can add favorites" ON favorite_recipes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can remove favorites" ON favorite_recipes FOR DELETE USING (user_id = auth.uid());

-- Promotional Flyers policies
CREATE POLICY "Everyone can view active flyers" ON promotional_flyers FOR SELECT USING (is_active = true);

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shopping_lists_updated_at BEFORE UPDATE ON shopping_lists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_shopping_items_updated_at BEFORE UPDATE ON shopping_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to clean old notifications (>7 days)
CREATE OR REPLACE FUNCTION clean_old_notifications()
RETURNS void AS $$
BEGIN
    DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$ language 'plpgsql';

-- ============================================================================
-- SEED DATA (Optional - Sample Categories)
-- ============================================================================

-- Sample promotional flyer (you can add more)
INSERT INTO promotional_flyers (supermarket_name, title, valid_from, valid_until, pages, is_active)
VALUES 
  ('Sample Market', 'Weekly Deals', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', '[]', false);

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================
-- After running this script:
-- 1. Configure Supabase Auth providers (Google, Apple, Email)
-- 2. Set up Storage buckets for images
-- 3. Configure Realtime for shopping_items and shopping_lists tables
-- 4. Set up Edge Functions for notifications and recipe scraping
-- 5. Add your Supabase URL and anon key to the Flutter app
-- ============================================================================
