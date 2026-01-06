# Database Structure Check - Before Migration

**Execute these queries in your Supabase SQL Editor to verify current state**

## 1. Check shopping_items Table Columns

```sql
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'shopping_items'
ORDER BY ordinal_position;
```

**Expected Current State** (BEFORE migration):
- Should have `category` column
- Should NOT have `category_id` column yet
- Should NOT have `language` column yet

---

## 2. Check recipes Table Columns

```sql
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'recipes'
ORDER BY ordinal_position;
```

**Expected Current State** (BEFORE migration):
- Should NOT have `language` column yet
- Should NOT have `translations` column yet

---

## 3. Check Existing Category Values

```sql
SELECT 
    category,
    COUNT(*) as item_count
FROM shopping_items
WHERE category IS NOT NULL
GROUP BY category
ORDER BY item_count DESC
LIMIT 20;
```

**Expected Output**:
You should see German category names like:
- "Obst & Gemüse"
- "Milchprodukte"
- "Fleisch & Fisch"
- "Backwaren"
- etc.

These will be migrated to IDs like:
- "fruits_vegetables"
- "dairy"
- "meat_fish"
- "bakery"

---

## 4. Check Current Indexes

```sql
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('shopping_items', 'recipes')
ORDER BY tablename, indexname;
```

**Expected Current State**:
- Should NOT have `idx_shopping_items_category_id` yet
- Should NOT have `idx_shopping_items_language` yet
- Should NOT have `idx_recipes_language` yet

---

## 5. Sample Data Check

```sql
-- Check a few sample items to see current structure
SELECT 
    id,
    name,
    category,
    created_at
FROM shopping_items
ORDER BY created_at DESC
LIMIT 10;
```

---

## What to Look For

### ✅ Before Migration (Current State):
- `shopping_items` has `category` column with German names
- NO `category_id` column
- NO `language` column
- `recipes` has NO `language` column
- Category values are German strings

### ✅ After Migration (Target State):
- `shopping_items` has `category` column (unchanged)
- `shopping_items` has NEW `category_id` column with IDs
- `shopping_items` has NEW `language` column ('de' or 'en')
- `recipes` has NEW `language` column
- `recipes` has NEW `translations` column (JSONB)
- Old category names migrated to IDs

---

## Migration Safety Checks

Before running migration:

1. **Backup Check**:
   ```sql
   -- Count total items (write this down)
   SELECT COUNT(*) FROM shopping_items;
   SELECT COUNT(*) FROM recipes;
   ```

2. **Category Distribution**:
   ```sql
   -- See which categories will be migrated
   SELECT category, COUNT(*) 
   FROM shopping_items 
   GROUP BY category;
   ```

---

## After Migration Verification

Run these to verify migration succeeded:

```sql
-- 1. Check new columns exist
SELECT column_name 
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'shopping_items'
  AND column_name IN ('category_id', 'language');

-- 2. Verify category_id migration
SELECT 
    category,
    category_id,
    COUNT(*) as count
FROM shopping_items
GROUP BY category, category_id
ORDER BY count DESC;

-- 3. Check language defaults
SELECT 
    language,
    COUNT(*) as count
FROM shopping_items
GROUP BY language;

-- 4. Verify no NULL category_ids
SELECT COUNT(*) as null_category_ids
FROM shopping_items
WHERE category_id IS NULL;
```

**Expected After Migration**:
- All items should have `category_id` populated
- All items should have `language = 'de'` (default)
- Old German category names preserved in `category` column
- New category IDs in `category_id` column

---

## Rollback Verification

If you need to rollback:

```sql
-- Verify columns were dropped
SELECT column_name 
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'shopping_items';

-- Should NOT see category_id or language if rollback succeeded
```
