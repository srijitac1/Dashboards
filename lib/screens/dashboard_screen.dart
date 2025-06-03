import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../widgets/narrative_block.dart';
import '../widgets/data_visualization.dart';
import '../widgets/voice_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshDashboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNarrativeSection(),
                      const SizedBox(height: 24),
                      _buildInsightsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNarrativeSection() {
    final geminiService = context.watch<GeminiService>();
    final narrative = geminiService.currentNarrative;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Narrative',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generateNarrative,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              narrative ?? 'No narrative generated yet. Click the refresh button to generate a narrative.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    final geminiService = context.watch<GeminiService>();
    final insights = geminiService.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (insights.isEmpty)
          const Center(
            child: Text('No insights available'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: insights.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(insights[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      // Navigate to insights screen
                      Navigator.pushNamed(context, '/insights');
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final geminiService = context.read<GeminiService>();
      await Future.wait([
        _generateNarrative(),
        _generateInsights(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh dashboard: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateNarrative() async {
    try {
      final geminiService = context.read<GeminiService>();
      // Sample data - replace with actual data from your app
      const sampleData = 'Sample data for narrative generation';
      await geminiService.generateNarrative(sampleData);
    } catch (e) {
      debugPrint('Error generating narrative: $e');
      rethrow;
    }
  }

  Future<void> _generateInsights() async {
    try {
      final geminiService = context.read<GeminiService>();
      // Sample data - replace with actual data from your app
      const sampleData = 'Sample data for insights generation';
      await geminiService.generateInsights('General', sampleData);
    } catch (e) {
      debugPrint('Error generating insights: $e');
      rethrow;
    }
  }
} 