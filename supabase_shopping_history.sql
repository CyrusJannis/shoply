-- Shopping History Schema

-- Drop existing tables if they exist (to fix schema)
DROP TABLE IF EXISTS shopping_history_items CASCADE;
DROP TABLE IF EXISTS shopping_history CASCADE;

-- Shopping History Table (completed shopping trips)
CREATE TABLE shopping_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    list_name TEXT NOT NULL,
    total_items INTEGER NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shopping History Items Table (items from completed trips)
CREATE TABLE IF NOT EXISTS shopping_history_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    history_id UUID NOT NULL REFERENCES shopping_history(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    quantity DOUBLE PRECISION DEFAULT 1.0,
    unit TEXT,
    category TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shopping_history_user_id ON shopping_history(user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_history_completed_at ON shopping_history(completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_shopping_history_items_history_id ON shopping_history_items(history_id);

-- Enable RLS
ALTER TABLE shopping_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE shopping_history_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shopping_history
CREATE POLICY "Users can view own history" ON shopping_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history" ON shopping_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own history" ON shopping_history
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for shopping_history_items
CREATE POLICY "Users can view own history items" ON shopping_history_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shopping_history
            WHERE shopping_history.id = shopping_history_items.history_id
            AND shopping_history.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own history items" ON shopping_history_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM shopping_history
            WHERE shopping_history.id = shopping_history_items.history_id
            AND shopping_history.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own history items" ON shopping_history_items
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM shopping_history
            WHERE shopping_history.id = shopping_history_items.history_id
            AND shopping_history.user_id = auth.uid()
        )
    );
