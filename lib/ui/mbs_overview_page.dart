import 'package:flutter/material.dart';
import 'widgets/ablerite_loading_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/focus_app_bar_actions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/navigation_service.dart';

class MBSOverviewPage extends StatefulWidget {
  const MBSOverviewPage({super.key});

  @override
  State<MBSOverviewPage> createState() => _MBSOverviewPageState();
}

class _MBSOverviewPageState extends State<MBSOverviewPage> {
  List<Item> _meditationLogs = [];
  List<Item> _bodyLogs = [];
  List<Item> _spiritLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    pushPage();
    _fetchAllLogs();
  }

  @override
  void dispose() {
    popPage();
    super.dispose();
  }

  Future<void> _fetchAllLogs() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all three types of logs in parallel
      final results = await Future.wait([
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'meditation_logs'),
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'body_logs'),
        Supabase.instance.client
            .from('items')
            .select()
            .eq('user_id', userId)
            .eq('section', 'spirit_logs'),
      ]);

      if (mounted) {
        setState(() {
          _meditationLogs = (results[0] as List)
              .map((e) => Item.fromJson(e))
              .toList();
          _bodyLogs = (results[1] as List)
              .map((e) => Item.fromJson(e))
              .toList();
          _spiritLogs = (results[2] as List)
              .map((e) => Item.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Get current month's date range
  Map<String, DateTime> _getCurrentMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    return {'start': startOfMonth, 'end': endOfMonth};
  }

  bool _isInCurrentMonth(String? dateStr) {
    if (dateStr == null || !dateStr.contains('-')) return false;
    final logDate = DateTime.tryParse(dateStr);
    if (logDate == null) return false;

    final range = _getCurrentMonthRange();
    return logDate.isAfter(range['start']!.subtract(const Duration(days: 1))) &&
        logDate.isBefore(range['end']!);
  }

  // Calculate monthly totals
  Map<String, int> _getMonthlyTotals() {
    int mind = 0, body = 0, spirit = 0;

    for (var log in _meditationLogs) {
      if (_isInCurrentMonth(log.date)) {
        mind += log.value ?? 0;
      }
    }

    for (var log in _bodyLogs) {
      if (_isInCurrentMonth(log.date)) {
        body += log.value ?? 0;
      }
    }

    for (var log in _spiritLogs) {
      if (_isInCurrentMonth(log.date)) {
        spirit += log.value ?? 0;
      }
    }

    return {
      'mind': mind,
      'body': body,
      'spirit': spirit,
      'total': mind + body + spirit,
    };
  }

  // Get weekly archives for the bar chart (last 12 weeks)
  List<Map<String, dynamic>> _getWeeklyArchives() {
    final List<Map<String, dynamic>> archives = [];
    final now = DateTime.now();

    // Go back 12 weeks
    for (int weekOffset = 11; weekOffset >= 0; weekOffset--) {
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday % 7 + weekOffset * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));

      int mind = 0, body = 0, spirit = 0;

      // Sum meditation logs
      for (var log in _meditationLogs) {
        final logDate = DateTime.tryParse(log.date ?? '');
        if (logDate != null &&
            logDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            logDate.isBefore(weekEnd)) {
          mind += log.value ?? 0;
        }
      }

      // Sum body logs
      for (var log in _bodyLogs) {
        final logDate = DateTime.tryParse(log.date ?? '');
        if (logDate != null &&
            logDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            logDate.isBefore(weekEnd)) {
          body += log.value ?? 0;
        }
      }

      // Sum spirit logs
      for (var log in _spiritLogs) {
        final logDate = DateTime.tryParse(log.date ?? '');
        if (logDate != null &&
            logDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            logDate.isBefore(weekEnd)) {
          spirit += log.value ?? 0;
        }
      }

      archives.add({
        'weekOf': DateFormat('yyyy-MM-dd').format(weekStart),
        'mind': mind,
        'body': body,
        'spirit': spirit,
        'total': mind + body + spirit,
      });
    }

    return archives;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _getMonthlyTotals();
    final weeklyArchives = _getWeeklyArchives();
    final total = monthlyTotals['total']!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const FocusAwareBackButton(),
        title: FocusAwareAppBarTitle(
          child: Text(
            'Wellness Metrics',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: const [FocusAppBarActions(guide: FocusHelpGuide.wellness)],
      ),
      body: _isLoading
          ? const Center(child: AbleriteLoadingIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final heightScale = (constraints.maxHeight / 640).clamp(
                  0.72,
                  1.0,
                );
                final widthScale = (constraints.maxWidth / 390).clamp(
                  0.82,
                  1.0,
                );
                final scale =
                    (heightScale < widthScale ? heightScale : widthScale)
                        .toDouble();
                final padding = 16.0 * scale;
                final gap = 12.0 * scale;

                return Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthlyBadge(total, scale),
                      SizedBox(height: gap),
                      _buildMonthlySummary(monthlyTotals, total, scale),
                      SizedBox(height: gap),
                      _buildOverviewText(total, scale),
                      SizedBox(height: gap),
                      Text(
                        'Weekly Breakdown',
                        style: GoogleFonts.outfit(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Expanded(
                        child: _buildWeeklyBreakdown(weeklyArchives, scale),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMonthlyBadge(int total, double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$total min this month',
        style: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(
    Map<String, int> monthlyTotals,
    int total,
    double scale,
  ) {
    final chartSize = 96.0 * scale;
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: chartSize,
            height: chartSize,
            child: total > 0
                ? CustomPaint(
                    painter: PieChartPainter(
                      mind: monthlyTotals['mind']!,
                      body: monthlyTotals['body']!,
                      spirit: monthlyTotals['spirit']!,
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.pie_chart,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(50),
                      size: 38 * scale,
                    ),
                  ),
          ),
          SizedBox(width: 18 * scale),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendItem('Mind', monthlyTotals['mind']!, Colors.blue),
                SizedBox(height: 10 * scale),
                _buildLegendItem('Body', monthlyTotals['body']!, Colors.red),
                SizedBox(height: 10 * scale),
                _buildLegendItem(
                  'Spirit',
                  monthlyTotals['spirit']!,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewText(int total, double scale) {
    final message = total > 0
        ? 'Balance your month by keeping mind, body, and spirit visible together. Use the weekly chart to spot where your practice is strong and where it needs attention.'
        : 'Start logging small practices across mind, body, and spirit. This overview will show your balance, rhythm, and weekly consistency as your data grows.';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * scale),
      decoration: _panelDecoration(),
      child: Text(
        message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.outfit(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(170),
          fontSize: 13 * scale,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildWeeklyBreakdown(
    List<Map<String, dynamic>> weeklyArchives,
    double scale,
  ) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Mind', Colors.blue),
              SizedBox(width: 16 * scale),
              _buildChartLegend('Body', Colors.red),
              SizedBox(width: 16 * scale),
              _buildChartLegend('Spirit', Colors.purple),
            ],
          ),
          SizedBox(height: 10 * scale),
          Expanded(child: _buildWeeklyChart(weeklyArchives)),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<Map<String, dynamic>> weeklyArchives) {
    if (weeklyArchives.isEmpty ||
        weeklyArchives.every((w) => w['total'] == 0)) {
      return Center(
        child: Text(
          'No weekly history yet',
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          ),
        ),
      );
    }

    final maxTotal = weeklyArchives.fold<int>(
      0,
      (max, w) => w['total'] > max ? w['total'] as int : max,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBarHeight = (constraints.maxHeight - 18).clamp(24.0, 220.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: weeklyArchives.map((entry) {
            final total = entry['total'] as int;
            final height = maxTotal > 0 ? total / maxTotal * maxBarHeight : 0.0;
            final mindPercent = total > 0
                ? (entry['mind'] as int) / total
                : 0.0;
            final bodyPercent = total > 0
                ? (entry['body'] as int) / total
                : 0.0;
            final spiritPercent = total > 0
                ? (entry['spirit'] as int) / total
                : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Week: ${DateFormat('MMM d').format(DateTime.tryParse(entry['weekOf']) ?? DateTime.now())}\n'
                              'Mind: ${entry['mind']}m\n'
                              'Body: ${entry['body']}m\n'
                              'Spirit: ${entry['spirit']}m\n'
                              'Total: ${entry['total']}m',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(30),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (mindPercent > 0)
                              Container(
                                height: height * mindPercent,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            if (bodyPercent > 0)
                              Container(
                                height: height * bodyPercent,
                                color: Colors.red,
                              ),
                            if (spiritPercent > 0)
                              Container(
                                height: height * spiritPercent,
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('M/d').format(
                        DateTime.tryParse(entry['weekOf']) ?? DateTime.now(),
                      ),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(100),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(100),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value min',
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final int mind;
  final int body;
  final int spirit;

  PieChartPainter({
    required this.mind,
    required this.body,
    required this.spirit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = mind + body + spirit;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = -90 * (3.14159 / 180); // Start from top

    // Draw Mind segment (Blue)
    if (mind > 0) {
      final sweepAngle = (mind / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw Body segment (Red)
    if (body > 0) {
      final sweepAngle = (body / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // Draw Spirit segment (Purple)
    if (spirit > 0) {
      final sweepAngle = (spirit / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
