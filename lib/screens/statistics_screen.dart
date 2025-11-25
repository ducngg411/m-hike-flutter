import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';
import '../services/share_service.dart';
import '../models/hike.dart';
import 'hike_details_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    final stats = await StatisticsService.getAllStatistics();
    setState(() {
      _statistics = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_statistics != null && _statistics!['totalHikes'] > 0)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final recentHikes = _statistics!['recentHikes'] as List<Hike>;
                ShareService.shareHikesSummary(recentHikes, _statistics!);
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics!['totalHikes'] == 0
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadStatistics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 16),
            _buildDifficultyChart(),
            const SizedBox(height: 16),
            _buildMonthlyChart(),
            const SizedBox(height: 16),
            _buildLocationsList(),
            const SizedBox(height: 16),
            _buildRecordCards(),
            const SizedBox(height: 16),
            _buildRecentHikes(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Statistics Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some hikes to see your statistics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Hikes',
                '${_statistics!['totalHikes']}',
                Icons.hiking,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Distance',
                '${_statistics!['totalDistance'].toStringAsFixed(1)} km',
                Icons.straighten,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Observations',
                '${_statistics!['totalObservations']}',
                Icons.photo_camera,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Distance',
                '${_statistics!['averageDistance'].toStringAsFixed(1)} km',
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'GPS Tracked',
                '${_statistics!['hikesWithGPS']}/${_statistics!['totalHikes']}',
                Icons.gps_fixed,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Favorite',
                '${_statistics!['favoriteLocation']}',
                Icons.favorite,
                Colors.pink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChart() {
    final difficultyData = _statistics!['difficultyDistribution'] as Map<String, int>;

    if (difficultyData.isEmpty) return const SizedBox.shrink();

    final colors = {
      'Easy': Colors.green,
      'Moderate': Colors.orange,
      'Difficult': Colors.red,
      'Very Difficult': Colors.red[900]!,
      'Expert': Colors.purple,
    };

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Difficulty Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: difficultyData.entries.map((entry) {
                    final total = difficultyData.values.fold<int>(0, (a, b) => a + b);
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);

                    return PieChartSectionData(
                      color: colors[entry.key] ?? Colors.grey,
                      value: entry.value.toDouble(),
                      title: '$percentage%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: difficultyData.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final monthlyData = _statistics!['monthlyHikes'] as Map<String, int>;

    if (monthlyData.isEmpty) return const SizedBox.shrink();

    final spots = monthlyData.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    final maxY = monthlyData.values.fold<int>(0, (a, b) => a > b ? a : b).toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Activity (Last 12 Months)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0 ? (maxY / 5) : 1,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
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
                          if (value.toInt() % 2 == 0 && value.toInt() < monthlyData.length) {
                            final key = monthlyData.keys.elementAt(value.toInt());
                            final month = key.split('-')[1];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                month,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: maxY > 0 ? maxY + 1 : 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    final locationData = _statistics!['locationDistribution'] as Map<String, int>;

    if (locationData.isEmpty) return const SizedBox.shrink();

    final sortedLocations = locationData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedLocations.take(5).map((entry) {
              final percentage = (entry.value / _statistics!['totalHikes'] * 100)
                  .toStringAsFixed(0);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} hikes ($percentage%)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / _statistics!['totalHikes'],
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCards() {
    final longestHike = _statistics!['longestHike'] as Hike?;
    final shortestHike = _statistics!['shortestHike'] as Hike?;

    if (longestHike == null || shortestHike == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Records',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: Colors.green[50],
          child: ListTile(
            leading: const Icon(Icons.emoji_events, color: Colors.green, size: 32),
            title: const Text(
              'Longest Hike',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${longestHike.name} - ${longestHike.length} km\n${longestHike.location}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HikeDetailsScreen(hike: longestHike),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          color: Colors.blue[50],
          child: ListTile(
            leading: const Icon(Icons.directions_walk, color: Colors.blue, size: 32),
            title: const Text(
              'Shortest Hike',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${shortestHike.name} - ${shortestHike.length} km\n${shortestHike.location}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HikeDetailsScreen(hike: shortestHike),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHikes() {
    final recentHikes = _statistics!['recentHikes'] as List<Hike>;

    if (recentHikes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Hikes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...recentHikes.map((hike) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  '${hike.length.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(hike.name),
              subtitle: Text('${hike.location} • ${hike.date}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HikeDetailsScreen(hike: hike),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}