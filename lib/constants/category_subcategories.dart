/// Category to Subcategories mapping
/// 
/// This file contains the mapping of main categories to their subcategories
/// as defined in the product listing requirements.
class CategorySubcategories {
  static const Map<String, List<String>> data = {
    'Electronics': [
      'Mobiles & Tablets',
      'Laptops & Computers',
      'Audio Devices',
      'Wearables',
      'Gaming & Consoles',
      'Cameras & Photography',
      'PC Parts',
      'Tech Accessories',
      'Home Appliances',
      'Other',
    ],
    'Furniture': [
      'Study Furniture',
      'Bedroom Furniture',
      'Storage & Shelves',
      'Room Décor',
      'Cleaning Supplies',
      'Other',
    ],
    'Books': [
      'Academic Textbooks',
      'Entrance/Exam Prep',
      'Novels & Fiction',
      'Non-Fiction / Self-help',
      'Notes & Lab Manuals',
      'Stationery',
      'Other',
    ],
    'Sports': [
      'Indoor Sports Gear',
      'Outdoor Sports Gear',
      'Gym & Fitness Equipment',
      'Cycling Gear & Accessories',
      'Trekking & Travel Gear',
      'Other',
    ],
    'Fashion': [
      "Men's Clothing",
      "Women's Clothing",
      'Unisex Clothing',
      'Footwear',
      'Bags & Backpacks',
      'Accessories',
      'Luxury Items',
      'Other',
    ],
    'Hobbies': [
      'Musical Instruments',
      'Art & Craft Supplies',
      'Board Games & Cards',
      'Collectibles & Posters',
      'Novelty Items',
      'Other',
    ],
    'Vehicles': [
      'Bicycles / E-Cycles',
      'Two-Wheelers (Scooters & Motorcycles)',
      'Four-Wheelers (Cars & Jeeps)',
      'Skateboards & Longboards',
      'Roller Skates / Inline Skates',
      'Transport Accessories',
      'Other',
    ],
    'Other': [
      'Daily Essentials',
      'General Utilities',
      'Home Tools',
      'Miscellaneous',
    ],
  };

  /// Get subcategories for a given category
  static List<String> getSubcategories(String category) {
    return data[category] ?? [];
  }

  /// Check if a category exists
  static bool hasCategory(String category) {
    return data.containsKey(category);
  }

  /// Get all available categories
  static List<String> get availableCategories => data.keys.toList();
}

