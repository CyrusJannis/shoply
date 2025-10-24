# 🗄️ Database Setup - Super Easy (2 Minutes)

## Step 1: Open Supabase (30 seconds)

1. Go to https://supabase.com
2. Click "Sign in"
3. Select your project (shoply)
4. Click "SQL Editor" in the left sidebar

## Step 2: Run the SQL (1 minute)

1. Click "New query" button
2. Open the file `RUN_THIS_SQL.sql` in this folder
3. **Copy EVERYTHING** from that file (Cmd+A, Cmd+C)
4. **Paste** into the Supabase SQL Editor (Cmd+V)
5. Click the **"RUN"** button (or press Cmd+Enter)

## Step 3: Verify (30 seconds)

You should see:
```
Success. No rows returned
```

That's it! ✅ Database is ready!

---

## What This Does

Creates 3 things:
1. **item_purchase_stats** table - Tracks what you buy
2. **last_accessed_at** column - Remembers your last list
3. **get_recommended_items()** function - Smart recommendations

---

## Troubleshooting

### Error: "relation already exists"
**Solution:** That's fine! It means the table already exists. The SQL is safe to run multiple times.

### Error: "permission denied"
**Solution:** Make sure you're logged into the correct Supabase project.

### Error: "syntax error"
**Solution:** Make sure you copied the ENTIRE file, including the first line.

---

## After This

Run your app:
```bash
flutter run
```

Then test:
1. Create a shopping list
2. Add items (milk, bread, eggs)
3. Check them off
4. Complete shopping
5. Open the list again
6. After 2-3 shopping trips, you'll see recommendations! 🎉

---

**That's all you need to do! The SQL file is ready to copy/paste! 📋**
