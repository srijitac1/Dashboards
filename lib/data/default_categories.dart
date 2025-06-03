import '../models/insight_model.dart';

final List<InsightCategory> defaultCategories = [
  InsightCategory(
    name: 'Performance',
    description: 'Business performance metrics and KPIs',
    prompt: 'Analyze the following performance metrics and provide key insights:',
    metrics: ['Revenue', 'Profit Margin', 'Customer Acquisition Cost', 'Customer Lifetime Value'],
  ),
  InsightCategory(
    name: 'User Engagement',
    description: 'User behavior and interaction metrics',
    prompt: 'Analyze the following user engagement data and provide key insights:',
    metrics: ['Active Users', 'Session Duration', 'Bounce Rate', 'Feature Usage'],
  ),
  InsightCategory(
    name: 'Revenue',
    description: 'Revenue and financial metrics',
    prompt: 'Analyze the following revenue data and provide key insights:',
    metrics: ['Monthly Recurring Revenue', 'Average Revenue Per User', 'Revenue Growth Rate'],
  ),
  InsightCategory(
    name: 'Customer Satisfaction',
    description: 'Customer feedback and satisfaction metrics',
    prompt: 'Analyze the following customer satisfaction data and provide key insights:',
    metrics: ['Net Promoter Score', 'Customer Satisfaction Score', 'Customer Effort Score'],
  ),
]; 