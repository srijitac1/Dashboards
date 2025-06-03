import 'package:flutter/foundation.dart';

class Insight {
  final String id;
  final String category;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Insight({
    required this.id,
    required this.category,
    required this.content,
    required this.timestamp,
    this.metadata = const {},
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String,
      category: json['category'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class InsightCategory {
  final String name;
  final String description;
  final String prompt;
  final List<String> metrics;
  final Map<String, dynamic> settings;

  InsightCategory({
    required this.name,
    required this.description,
    required this.prompt,
    this.metrics = const [],
    this.settings = const {},
  });

  factory InsightCategory.fromJson(Map<String, dynamic> json) {
    return InsightCategory(
      name: json['name'] as String,
      description: json['description'] as String,
      prompt: json['prompt'] as String,
      metrics: List<String>.from(json['metrics'] as List? ?? []),
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'prompt': prompt,
      'metrics': metrics,
      'settings': settings,
    };
  }
} 