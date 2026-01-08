class PromotionalBanner {
  final String id;
  final String position;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final String? buttonColor;
  final String? textColor;
  final String bgColor;
  final String? imageUrl;
  final String? actionType;
  final String? actionUrl;
  final String? registrationUrl; // Full URL for web-based registration (opens in WebView)
  final bool isActive;
  final int priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? targetAudience;
  final List<String> tags;

  PromotionalBanner({
    required this.id,
    required this.position,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.buttonColor,
    this.textColor,
    required this.bgColor,
    this.imageUrl,
    this.actionType,
    this.actionUrl,
    this.registrationUrl,
    required this.isActive,
    required this.priority,
    this.startDate,
    this.endDate,
    this.targetAudience,
    required this.tags,
  });

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['id'] ?? '',
      position: json['position'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      buttonText: json['buttonText'],
      buttonColor: json['buttonColor'],
      textColor: json['textColor'],
      bgColor: json['bgColor'] ?? '#000000',
      imageUrl: json['imageUrl'],
      actionType: json['actionType'],
      actionUrl: json['actionUrl'],
      registrationUrl: json['registrationUrl'],
      isActive: json['isActive'] ?? true,
      priority: json['priority'] ?? 0,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      targetAudience: json['targetAudience'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': position,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'buttonColor': buttonColor,
      'textColor': textColor,
      'bgColor': bgColor,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionUrl': actionUrl,
      'registrationUrl': registrationUrl,
      'isActive': isActive,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'targetAudience': targetAudience,
      'tags': tags,
    };
  }
}

