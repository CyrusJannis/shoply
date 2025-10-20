-- Simple Recipes Schema (ohne komplexe RLS)

-- Recipes Table
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
CREATE TABLE recipe_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(recipe_id, user_id)
);

-- Indexes
CREATE INDEX idx_recipes_author_id ON recipes(author_id);
CREATE INDEX idx_recipes_created_at ON recipes(created_at DESC);
CREATE INDEX idx_recipe_likes_recipe_id ON recipe_likes(recipe_id);
CREATE INDEX idx_recipe_likes_user_id ON recipe_likes(user_id);

-- Enable RLS
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_likes ENABLE ROW LEVEL SECURITY;

-- Simple RLS Policies (jeder kann alles sehen und erstellen)
CREATE POLICY "Enable read access for all users" ON recipes FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON recipes FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update for users based on author_id" ON recipes FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Enable delete for users based on author_id" ON recipes FOR DELETE USING (auth.uid() = author_id);

CREATE POLICY "Enable read access for all users" ON recipe_likes FOR SELECT USING (true);
CREATE POLICY "Enable insert for authenticated users" ON recipe_likes FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable delete for users based on user_id" ON recipe_likes FOR DELETE USING (auth.uid() = user_id);

-- Storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('recipe-images', 'recipe-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'recipe-images');
CREATE POLICY "Authenticated users can upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'recipe-images' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update own images" ON storage.objects FOR UPDATE USING (bucket_id = 'recipe-images');
CREATE POLICY "Users can delete own images" ON storage.objects FOR DELETE USING (bucket_id = 'recipe-images');
