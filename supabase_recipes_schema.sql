-- Recipes Table
CREATE TABLE IF NOT EXISTS recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    prep_time_minutes INTEGER NOT NULL,
    cook_time_minutes INTEGER NOT NULL,
    default_servings INTEGER NOT NULL,
    ingredients JSONB NOT NULL,
    instructions TEXT[] NOT NULL,
    author_id UUID NOT NULL,
    author_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recipe Likes Table
CREATE TABLE IF NOT EXISTS recipe_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_recipes_author_id ON recipes(author_id);
CREATE INDEX IF NOT EXISTS idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_recipe_id ON recipe_likes(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_likes_user_id ON recipe_likes(user_id);

-- Full text search index for recipe names
CREATE INDEX IF NOT EXISTS idx_recipes_name_search ON recipes USING gin(to_tsvector('english', name));

-- Enable Row Level Security
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_likes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for recipes
CREATE POLICY "Anyone can view recipes"
    ON recipes FOR SELECT
    USING (true);

CREATE POLICY "Users can create their own recipes"
    ON recipes FOR INSERT
    WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Users can update their own recipes"
    ON recipes FOR UPDATE
    USING (auth.uid() = author_id);

CREATE POLICY "Users can delete their own recipes"
    ON recipes FOR DELETE
    USING (auth.uid() = author_id);

-- RLS Policies for recipe_likes
CREATE POLICY "Anyone can view recipe likes"
    ON recipe_likes FOR SELECT
    USING (true);

CREATE POLICY "Users can like recipes"
    ON recipe_likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike recipes"
    ON recipe_likes FOR DELETE
    USING (auth.uid() = user_id);

-- Storage bucket for recipe images
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-images', 'recipe-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Anyone can view recipe images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'recipe-images');

CREATE POLICY "Authenticated users can upload recipe images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'recipe-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Users can update their own recipe images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'recipe-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their own recipe images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'recipe-images' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_recipes_updated_at
    BEFORE UPDATE ON recipes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
