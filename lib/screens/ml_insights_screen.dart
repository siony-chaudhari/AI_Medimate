import 'package:flutter/material.dart';
import '/services/ml_rescheduling_service.dart';
import '/utils/constants.dart';

/// Screen to display ML insights and statistics
class MLInsightsScreen extends StatefulWidget {
  const MLInsightsScreen({super.key});

  @override
  State<MLInsightsScreen> createState() => _MLInsightsScreenState();
}

class _MLInsightsScreenState extends State<MLInsightsScreen> {
  Map<String, dynamic>? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final mlService = MLReschedulingService();
      await mlService.initialize();
      final insights = mlService.getMLInsights();
      
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading ML insights: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ML Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights == null
              ? _buildNoDataView()
              : _buildInsightsView(),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No ML Data Yet',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start taking or missing medications to build your behavior patterns',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsView() {
    final mostSuccessfulHour = _insights!['most_successful_hour'] as int;
    final overallAdherence = (_insights!['overall_adherence'] as double) * 100;
    final mostMissedDay = _insights!['most_missed_day'] as String;
    final totalDataPoints = _insights!['total_data_points'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Learning Active',
                        style: AppTextStyles.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalDataPoints data points collected',
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Insights Cards
          _buildInsightCard(
            'Most Successful Hour',
            _formatHour(mostSuccessfulHour),
            'You take medications most successfully at this time',
            Icons.access_time,
            Colors.green,
          ),

          const SizedBox(height: 16),

          _buildInsightCard(
            'Overall Adherence',
            '${overallAdherence.toStringAsFixed(1)}%',
            overallAdherence >= 80
                ? 'Excellent! Keep up the great work'
                : overallAdherence >= 60
                    ? 'Good progress, room for improvement'
                    : 'Let\'s work on improving this together',
            Icons.trending_up,
            overallAdherence >= 80
                ? Colors.green
                : overallAdherence >= 60
                    ? Colors.orange
                    : Colors.red,
          ),

          const SizedBox(height: 16),

          _buildInsightCard(
            'Most Missed Day',
            mostMissedDay,
            'Consider setting extra reminders on this day',
            Icons.calendar_today,
            Colors.orange,
          ),

          const SizedBox(height: 24),

          // How ML Works Section
          Text(
            'How ML Rescheduling Works',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildHowItWorksCard(
            '1. Pattern Recognition',
            'AI analyzes when you successfully take medications',
            Icons.pattern,
          ),

          _buildHowItWorksCard(
            '2. Smart Prediction',
            'Predicts optimal reschedule times based on your habits',
            Icons.lightbulb_outline,
          ),

          _buildHowItWorksCard(
            '3. Auto Rescheduling',
            'Automatically reschedules missed doses at better times',
            Icons.schedule,
          ),

          _buildHowItWorksCard(
            '4. Continuous Learning',
            'Gets smarter with every interaction',
            Icons.psychology,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}
