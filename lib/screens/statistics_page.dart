import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_word_app/services/statistics_service.dart';
import 'package:isar/isar.dart';

class StatisticsPage extends StatefulWidget {
  final Isar isar;

  const StatisticsPage({Key? key, required this.isar}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatisticsService _statsService;
  late Future<int> _totalWordsFuture;
  late Future<Map<int, int>> _repetitionLevelsFuture;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _statsService = StatisticsService(widget.isar);
    _refreshData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _totalWordsFuture = _statsService.getTotalWordCount();
      _repetitionLevelsFuture = _statsService.getWordsByRepetitionLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime İstatistikleri'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Toplam kelime istatistiği
            FutureBuilder<int>(
              future: _totalWordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Kelime',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sayısı',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${snapshot.data ?? 0}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Tekrar seviyeleri istatistiği
            FutureBuilder<Map<int, int>>(
              future: _repetitionLevelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data ?? {};
                final levels =
                    data.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));

                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tekrar Seviyeleri',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelime tekrar seviyelerine göre dağılım',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pie Chart ve Açıklamalar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Pie Chart
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: PieChart(
                                PieChartData(
                                  sections:
                                      levels.map((entry) {
                                        return PieChartSectionData(
                                          value: entry.value.toDouble(),
                                          color: _getColorForLevel(
                                            entry.key,
                                            colorScheme,
                                          ),
                                          title:
                                              entry.value > 0
                                                  ? '${entry.value}'
                                                  : '',
                                          radius: 18,
                                          titleStyle: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                        );
                                      }).toList(),
                                  sectionsSpace: 1,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Açıklamalar
                            Expanded(
                              child: Column(
                                children:
                                    levels.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _getColorForLevel(
                                                  entry.key,
                                                  colorScheme,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Seviye ${entry.key}',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.9),
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              '${entry.value}',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Toplam Bilgisi
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Toplam Kelime',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                '${levels.fold(0, (sum, item) => sum + item.value)}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(int level, ColorScheme colorScheme) {
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
    ];
    return colors[level % colors.length];
  }
}
