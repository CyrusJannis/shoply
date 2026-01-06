import WidgetKit
import SwiftUI

// MARK: - Shopping List Widget

struct ShoppingListEntry: TimelineEntry {
    let date: Date
    let listName: String
    let items: [ShoppingItem]
    let itemCount: Int
    let checkedCount: Int
}

struct ShoppingItem: Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let isChecked: Bool
}

struct ShoppingListProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoppingListEntry {
        ShoppingListEntry(
            date: Date(),
            listName: "Shopping List",
            items: [
                ShoppingItem(id: "1", name: "Milk", quantity: 1, isChecked: false),
                ShoppingItem(id: "2", name: "Bread", quantity: 2, isChecked: true),
                ShoppingItem(id: "3", name: "Eggs", quantity: 12, isChecked: false),
            ],
            itemCount: 3,
            checkedCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ShoppingListEntry) -> Void) {
        let entry = loadShoppingListData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingListEntry>) -> Void) {
        let entry = loadShoppingListData()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadShoppingListData() -> ShoppingListEntry {
        let defaults = UserDefaults(suiteName: "group.com.shoply.app")
        
        guard let jsonString = defaults?.string(forKey: "widget_shopping_list"),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ShoppingListEntry(
                date: Date(),
                listName: "No List Selected",
                items: [],
                itemCount: 0,
                checkedCount: 0
            )
        }
        
        let listName = json["listName"] as? String ?? "Shopping List"
        let itemCount = json["itemCount"] as? Int ?? 0
        let checkedCount = json["checkedCount"] as? Int ?? 0
        
        var items: [ShoppingItem] = []
        if let itemsArray = json["items"] as? [[String: Any]] {
            items = itemsArray.prefix(10).compactMap { item in
                guard let id = item["id"] as? String,
                      let name = item["name"] as? String else { return nil }
                return ShoppingItem(
                    id: id,
                    name: name,
                    quantity: item["quantity"] as? Int ?? 1,
                    isChecked: item["isChecked"] as? Bool ?? false
                )
            }
        }
        
        return ShoppingListEntry(
            date: Date(),
            listName: listName,
            items: items,
            itemCount: itemCount,
            checkedCount: checkedCount
        )
    }
}

struct ShoppingListWidgetEntryView: View {
    var entry: ShoppingListProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.green)
                Text(entry.listName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text("\(entry.checkedCount)/\(entry.itemCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Items
            if entry.items.isEmpty {
                VStack {
                    Image(systemName: "cart")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxItems = family == .systemSmall ? 3 : (family == .systemMedium ? 4 : 8)
                ForEach(entry.items.filter { !$0.isChecked }.prefix(maxItems)) { item in
                    HStack {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(item.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        if item.quantity > 1 {
                            Text("×\(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                }
                
                if entry.items.filter({ !$0.isChecked }).count > maxItems {
                    Text("+\(entry.items.filter({ !$0.isChecked }).count - maxItems) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "shoply://lists"))
    }
}

struct ShoppingListWidget: Widget {
    let kind: String = "ShoppingListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoppingListProvider()) { entry in
            ShoppingListWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Shopping List")
        .description("View your shopping list items")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Saved Recipes Widget

struct SavedRecipesEntry: TimelineEntry {
    let date: Date
    let recipes: [RecipeItem]
    let recipeCount: Int
}

struct RecipeItem: Identifiable {
    let id: String
    let name: String
    let imageUrl: String?
    let cookTime: Int?
    let rating: Double?
}

struct SavedRecipesProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavedRecipesEntry {
        SavedRecipesEntry(
            date: Date(),
            recipes: [
                RecipeItem(id: "1", name: "Spaghetti Carbonara", imageUrl: nil, cookTime: 30, rating: 4.5),
                RecipeItem(id: "2", name: "Chicken Curry", imageUrl: nil, cookTime: 45, rating: 4.8),
            ],
            recipeCount: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SavedRecipesEntry) -> Void) {
        let entry = loadSavedRecipesData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SavedRecipesEntry>) -> Void) {
        let entry = loadSavedRecipesData()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadSavedRecipesData() -> SavedRecipesEntry {
        let defaults = UserDefaults(suiteName: "group.com.shoply.app")
        
        guard let jsonString = defaults?.string(forKey: "widget_saved_recipes"),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return SavedRecipesEntry(date: Date(), recipes: [], recipeCount: 0)
        }
        
        let recipeCount = json["recipeCount"] as? Int ?? 0
        
        var recipes: [RecipeItem] = []
        if let recipesArray = json["recipes"] as? [[String: Any]] {
            recipes = recipesArray.prefix(6).compactMap { recipe in
                guard let id = recipe["id"] as? String,
                      let name = recipe["name"] as? String else { return nil }
                return RecipeItem(
                    id: id,
                    name: name,
                    imageUrl: recipe["imageUrl"] as? String,
                    cookTime: recipe["cookTime"] as? Int,
                    rating: recipe["rating"] as? Double
                )
            }
        }
        
        return SavedRecipesEntry(date: Date(), recipes: recipes, recipeCount: recipeCount)
    }
}

struct SavedRecipesWidgetEntryView: View {
    var entry: SavedRecipesProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Saved Recipes")
                    .font(.headline)
                Spacer()
                Text("\(entry.recipeCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Recipes
            if entry.recipes.isEmpty {
                VStack {
                    Image(systemName: "heart")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No saved recipes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxRecipes = family == .systemSmall ? 2 : (family == .systemMedium ? 3 : 5)
                ForEach(entry.recipes.prefix(maxRecipes)) { recipe in
                    Link(destination: URL(string: "shoply://recipes/\(recipe.id)")!) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(recipe.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            if let cookTime = recipe.cookTime {
                                Text("\(cookTime)m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let rating = recipe.rating {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "shoply://recipes/saved"))
    }
}

struct SavedRecipesWidget: Widget {
    let kind: String = "SavedRecipesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavedRecipesProvider()) { entry in
            SavedRecipesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Saved Recipes")
        .description("Quick access to your favorite recipes")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct ShoplyWidgetBundle: WidgetBundle {
    var body: some Widget {
        ShoppingListWidget()
        SavedRecipesWidget()
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    ShoppingListWidget()
} timeline: {
    ShoppingListEntry(
        date: Date(),
        listName: "Groceries",
        items: [
            ShoppingItem(id: "1", name: "Milk", quantity: 1, isChecked: false),
            ShoppingItem(id: "2", name: "Bread", quantity: 2, isChecked: false),
        ],
        itemCount: 5,
        checkedCount: 2
    )
}

#Preview(as: .systemMedium) {
    SavedRecipesWidget()
} timeline: {
    SavedRecipesEntry(
        date: Date(),
        recipes: [
            RecipeItem(id: "1", name: "Spaghetti Carbonara", imageUrl: nil, cookTime: 30, rating: 4.5),
            RecipeItem(id: "2", name: "Chicken Curry", imageUrl: nil, cookTime: 45, rating: 4.8),
        ],
        recipeCount: 2
    )
}
