import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../models/insight_model.dart';
import '../repositories/insight_repository.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<InsightCategory> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<InsightRepository>();
      final categories = await repository.getCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = categories.first.name;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load categories: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInsights,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategorySelector(),
          Expanded(
            child: _buildInsightsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateNewInsight,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Select Category',
          border: OutlineInputBorder(),
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category.name,
            child: Text(category.name),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCategory = value;
            });
            _refreshInsights();
          }
        },
      ),
    );
  }

  Widget _buildInsightsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshInsights,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_selectedCategory == null) {
      return const Center(
        child: Text('Please select a category'),
      );
    }

    final geminiService = context.watch<GeminiService>();
    final insights = geminiService.categoryInsights[_selectedCategory] ?? [];

    if (insights.isEmpty) {
      return const Center(
        child: Text('No insights available for this category'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insights[index],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _analyzeInsight(insights[index]),
                      child: const Text('Analyze'),
                    ),
                    TextButton(
                      onPressed: () => _shareInsight(insights[index]),
                      child: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refreshInsights() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final geminiService = context.read<GeminiService>();
      final repository = context.read<InsightRepository>();
      final category = _categories.firstWhere((c) => c.name == _selectedCategory);
      
      // Generate sample data based on category metrics
      final sampleData = category.metrics.map((metric) => '$metric: Sample value').join('\n');
      await geminiService.generateInsights(_selectedCategory!, sampleData);
    } catch (e) {
      setState(() {
        _error = 'Failed to load insights: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNewInsight() async {
    if (_selectedCategory == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final geminiService = context.read<GeminiService>();
      final repository = context.read<InsightRepository>();
      final category = _categories.firstWhere((c) => c.name == _selectedCategory);
      
      // Generate sample data based on category metrics
      final sampleData = category.metrics.map((metric) => '$metric: Sample value').join('\n');
      await geminiService.generateInsights(_selectedCategory!, sampleData);
    } catch (e) {
      setState(() {
        _error = 'Failed to generate insight: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeInsight(String insight) async {
    if (_selectedCategory == null) return;

    try {
      final geminiService = context.read<GeminiService>();
      final analysis = await geminiService.generateComparativeAnalysis(
        [insight],
        _selectedCategory!,
      );
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Analysis'),
          content: SingleChildScrollView(
            child: Text(analysis),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze insight: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareInsight(String insight) async {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality to be implemented'),
      ),
    );
  }
} 