import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/insight_model.dart';
import '../repositories/insight_repository.dart';

class GeminiService extends ChangeNotifier {
  static const String _apiKeyKey = 'gemini_api_key';
  final _storage = const FlutterSecureStorage();
  GenerativeModel? _model;
  String? _apiKey;
  String? _currentNarrative;
  List<String> _insights = [];
  Map<String, List<String>> _categoryInsights = {};
  final InsightRepository _repository = InsightRepository();
  final _uuid = const Uuid();

  String? get currentNarrative => _currentNarrative;
  List<String> get insights => _insights;
  Map<String, List<String>> get categoryInsights => _categoryInsights;

  GeminiService() {
    initialize();
  }

  Future<void> initialize() async {
    _apiKey = await _storage.read(key: _apiKeyKey);
    if (_apiKey != null) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey!,
      );
    }
  }

  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
    notifyListeners();
  }

  Future<String> generateNarrative(String prompt) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      _currentNarrative = response.text ?? '';
      notifyListeners();
      return _currentNarrative!;
    } catch (e) {
      debugPrint('Error generating narrative: $e');
      rethrow;
    }
  }

  Future<List<String>> generateInsights(String category, String data) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = 'Analyze the following data for $category and provide key insights:\n$data';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      final insights = (response.text ?? '').split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      
      _insights = insights;
      _categoryInsights[category] = insights;
      notifyListeners();
      
      return insights;
    } catch (e) {
      debugPrint('Error generating insights: $e');
      rethrow;
    }
  }

  Future<String> generateComparativeAnalysis(List<String> dataPoints, String category) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = 'Compare and analyze the following data points for $category:\n${dataPoints.join('\n')}';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      debugPrint('Error generating comparative analysis: $e');
      rethrow;
    }
  }

  Future<String> generateTrendAnalysis(List<String> dataPoints, String category) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = 'Analyze trends in the following data points for $category:\n${dataPoints.join('\n')}';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      debugPrint('Error generating trend analysis: $e');
      rethrow;
    }
  }

  Future<String> generateRecommendation(String category, String data) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final prompt = 'Based on the following data for $category, provide actionable recommendations:\n$data';
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? '';
    } catch (e) {
      debugPrint('Error generating recommendation: $e');
      rethrow;
    }
  }

  void clearInsights() {
    _insights = [];
    _categoryInsights.clear();
    notifyListeners();
  }

  Future<Insight> generateInsight(String data, {String? category}) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final categories = await _repository.getCategories();
      final targetCategory = category != null
          ? categories.firstWhere((c) => c.name == category)
          : categories.first;

      String prompt = '''Analyze the following business data and provide detailed insights for ${targetCategory.name}:
$data

Please provide:
1. Key findings
2. Trends and patterns
3. Potential opportunities
4. Recommendations
5. Risk factors

Format the response in a clear, structured way.''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final insight = response.text ?? 'No insight generated';

      final newInsight = Insight(
        id: _uuid.v4(),
        category: targetCategory.name,
        content: insight,
        timestamp: DateTime.now(),
        metadata: {
          'prompt': prompt,
          'metrics': targetCategory.metrics,
        },
      );

      await _repository.saveInsight(newInsight);
      notifyListeners();
      return newInsight;
    } catch (e) {
      debugPrint('Error generating insight: $e');
      rethrow;
    }
  }

  Future<Insight> generateRecommendations(String context, String category) async {
    if (_model == null) {
      throw Exception('API key not set');
    }

    try {
      final content = [
        Content.text(
          '''Based on the following business context for $category: $context

Please provide:
1. Strategic recommendations
2. Implementation steps
3. Resource requirements
4. Timeline suggestions
5. Success metrics

Format the response in a clear, actionable way.''',
        ),
      ];

      final response = await _model!.generateContent(content);
      final recommendations = response.text ?? 'No recommendations generated';

      final newInsight = Insight(
        id: _uuid.v4(),
        category: category,
        content: recommendations,
        timestamp: DateTime.now(),
        metadata: {
          'type': 'recommendations',
          'context': context,
        },
      );

      await _repository.saveInsight(newInsight);
      notifyListeners();
      return newInsight;
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      rethrow;
    }
  }

  Future<List<Insight>> getInsights(String category) async {
    return _repository.getInsights(category);
  }

  Future<List<InsightCategory>> getCategories() async {
    return _repository.getCategories();
  }

  Future<void> addCategory(InsightCategory category) async {
    await _repository.addCategory(category);
    notifyListeners();
  }

  Future<void> updateCategory(InsightCategory category) async {
    await _repository.updateCategory(category);
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryName) async {
    await _repository.deleteCategory(categoryName);
    notifyListeners();
  }

  bool get isInitialized => _model != null;
} 