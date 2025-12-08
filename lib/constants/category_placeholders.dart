/// Category-specific placeholder texts for product listing form
/// 
/// This file contains dynamic placeholder text that changes based on the
/// selected product category to provide relevant examples to users.
class CategoryPlaceholders {
  static const Map<String, Map<String, String>> data = {
    'Electronics': {
      'title': 'Eg: Samsung A14 for urgent sale',
      'price': '15000',
      'description': 'Charger and box included',
      'productName': 'Eg: Samsung Galaxy A14',
      'year': '2023',
      'brandName': 'Eg: Samsung, Apple, OnePlus',
    },
    'Furniture': {
      'title': 'Eg: Study table with chair - Moving out sale',
      'price': '2500',
      'description': 'Wooden desk, minor scratches, sturdy build',
      'productName': 'Eg: L-Shaped Study Desk',
      'year': '2022',
      'brandName': 'Eg: IKEA, Pepperfry, Urban Ladder',
    },
    'Books': {
      'title': 'Eg: Engineering Mathematics Textbook Sem 3',
      'price': '400',
      'description': 'Minimal highlighting, all pages intact, no tears',
      'productName': 'Eg: Higher Engineering Mathematics',
      'year': '2023',
      'brandName': 'Eg: Pearson, McGraw Hill, Wiley',
    },
    'Sports': {
      'title': 'Eg: Badminton racket with cover',
      'price': '1200',
      'description': 'Used for 6 months, strings intact',
      'productName': 'Eg: Yonex Nanoray Light',
      'year': '2023',
      'brandName': 'Eg: Yonex, Nike, Adidas',
    },
    'Fashion': {
      'title': 'Eg: Denim jacket - Size M',
      'price': '800',
      'description': 'Worn twice, perfect fit, no damages',
      'productName': 'Eg: Blue Denim Jacket',
      'year': '2024',
      'brandName': 'Eg: Levi\'s, H&M, Zara',
    },
    'Hobbies': {
      'title': 'Eg: Acoustic guitar with bag and picks',
      'price': '3500',
      'description': 'Well maintained, perfect for beginners',
      'productName': 'Eg: Yamaha F310 Acoustic Guitar',
      'year': '2022',
      'brandName': 'Eg: Yamaha, Fender, Gibson',
    },
    'Vehicles': {
      'title': 'Eg: Hero Splendor - Well maintained',
      'price': '25000',
      'description': 'Single owner, all papers clear, regular service',
      'productName': 'Eg: Hero Splendor Plus',
      'year': '2020',
      'brandName': 'Eg: Hero, Honda, Bajaj',
    },
    'Other': {
      'title': 'Eg: Mini refrigerator for dorm room',
      'price': '3000',
      'description': 'Working perfectly, energy efficient',
      'productName': 'Eg: Mini Fridge 50L',
      'year': '2023',
      'brandName': 'Eg: LG, Samsung, Whirlpool',
    },
  };

  /// Get placeholder text for a specific field in a category
  /// 
  /// [category] - The selected product category
  /// [field] - The field name (title, price, description, etc.)
  /// Returns the placeholder text, or a default value if not found
  static String getPlaceholder(String category, String field) {
    return data[category]?[field] ?? _getDefaultPlaceholder(field);
  }

  /// Default placeholders if category is not found
  static String _getDefaultPlaceholder(String field) {
    switch (field) {
      case 'title':
        return 'Eg: Product title';
      case 'price':
        return '1000';
      case 'description':
        return 'Describe your product features';
      case 'productName':
        return 'Eg: Product Name';
      case 'year':
        return '2023';
      case 'brandName':
        return 'Eg: Brand Name';
      default:
        return '';
    }
  }

  /// Check if a category has custom placeholders
  static bool hasCategory(String category) {
    return data.containsKey(category);
  }

  /// Get all available categories
  static List<String> get availableCategories => data.keys.toList();
}

