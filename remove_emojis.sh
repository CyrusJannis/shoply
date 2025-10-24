#!/bin/bash

# Emoji Removal Script
# This script finds and lists all files containing emojis

echo "🔍 Searching for emojis in codebase..."
echo ""

# Search for common emoji patterns
echo "Files containing emojis:"
echo "========================"

# Search in Dart files
grep -r -l "[\x{1F300}-\x{1F9FF}]" lib/ --include="*.dart" 2>/dev/null || echo "No emojis found in lib/"

# Alternative: Search for specific emoji characters
echo ""
echo "Specific emoji occurrences:"
echo "==========================="

# Fruits & Vegetables
echo "🥬 🥗 🍎 🥕 🍅 🥦"
grep -rn "🥬\|🥗\|🍎\|🥕\|🍅\|🥦" lib/ --include="*.dart" 2>/dev/null

# Meat & Dairy
echo "🥩 🥛 🧀"
grep -rn "🥩\|🥛\|🧀" lib/ --include="*.dart" 2>/dev/null

# Bakery & Grains
echo "🍞 🌾 🥫"
grep -rn "🍞\|🌾\|🥫" lib/ --include="*.dart" 2>/dev/null

# Other food
echo "🍝 🍚 🍖 🥑"
grep -rn "🍝\|🍚\|🍖\|🥑" lib/ --include="*.dart" 2>/dev/null

# Symbols
echo "⚡ ⏰ 🌱 💪 🎉 🎄 🌸 🧊"
grep -rn "⚡\|⏰\|🌱\|💪\|🎉\|🎄\|🌸\|🧊" lib/ --include="*.dart" 2>/dev/null

echo ""
echo "✅ Search complete!"
echo ""
echo "Next steps:"
echo "1. Review the files listed above"
echo "2. Replace emojis with Material Icons"
echo "3. Update category_mapper.dart"
echo "4. Update categories.dart"
echo "5. Update recipes_screen.dart"
