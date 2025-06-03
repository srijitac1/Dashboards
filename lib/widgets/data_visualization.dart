import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';

class DataVisualization extends StatefulWidget {
  const DataVisualization({Key? key}) : super(key: key);

  @override
  State<DataVisualization> createState() => _DataVisualizationState();
}

class _DataVisualizationState extends State<DataVisualization> {
  String _selectedMetric = 'Revenue';
  final Map<String, List<FlSpot>> _data = {
    'Revenue': [
      const FlSpot(0, 100),
      const FlSpot(1, 120),
      const FlSpot(2, 115),
      const FlSpot(3, 130),
      const FlSpot(4, 140),
      const FlSpot(5, 150),
    ],
    'Users': [
      const FlSpot(0, 8000),
      const FlSpot(1, 8500),
      const FlSpot(2, 9000),
      const FlSpot(3, 9500),
      const FlSpot(4, 10000),
      const FlSpot(5, 10500),
    ],
    'Growth': [
      const FlSpot(0, 10),
      const FlSpot(1, 12),
      const FlSpot(2, 11),
      const FlSpot(3, 13),
      const FlSpot(4, 14),
      const FlSpot(5, 15),
    ],
  };

  final Map<String, String> _currentValues = {
    'Revenue': '\$150K',
    'Users': '10.5K',
    'Growth': '+15%',
  };

  final Map<String, IconData> _icons = {
    'Revenue': Icons.attach_money,
    'Users': Icons.people,
    'Growth': Icons.trending_up,
  };

  final Map<String, Color> _colors = {
    'Revenue': Colors.green,
    'Users': Colors.blue,
    'Growth': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                DropdownButton<String>(
                  value: _selectedMetric,
                  items: _data.keys.map((String metric) {
                    return DropdownMenuItem<String>(
                      value: metric,
                      child: Text(metric),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedMetric = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Q${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _data[_selectedMetric]!,
                      isCurved: true,
                      color: _colors[_selectedMetric]!,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _colors[_selectedMetric]!.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _data.keys.map((metric) {
                return _buildMetricCard(
                  context,
                  metric,
                  _currentValues[metric]!,
                  _icons[metric]!,
                  _colors[metric]!,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMetric = title;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 