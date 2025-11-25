import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/observation.dart';
import '../models/hike.dart';
import 'hike_details_screen.dart';
import '../widgets/image_preview_widget.dart';

class AllObservationsScreen extends StatefulWidget {
  const AllObservationsScreen({super.key});

  @override
  State<AllObservationsScreen> createState() => _AllObservationsScreenState();
}

class _AllObservationsScreenState extends State<AllObservationsScreen> {
  List<ObservationWithHike> _observations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllObservations();
  }

  Future<void> _loadAllObservations() async {
    setState(() => _isLoading = true);

    final hikes = await DatabaseHelper.instance.getAllHikes();
    final List<ObservationWithHike> allObservations = [];

    debugPrint('All Observations Screen: Found ${hikes.length} hikes');

    for (final hike in hikes) {
      final observations = await DatabaseHelper.instance
          .getObservationsForHike(hike.id!);

      debugPrint('Hike "${hike.name}" has ${observations.length} observations');

      for (final obs in observations) {
        allObservations.add(ObservationWithHike(
          observation: obs,
          hike: hike,
        ));
      }
    }

    allObservations.sort((a, b) =>
        b.observation.time.compareTo(a.observation.time));

    debugPrint('Total observations to display: ${allObservations.length}');

    setState(() {
      _observations = allObservations;
      _isLoading = false;
    });
  }

  String _formatDateTime(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Observations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _observations.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_alt_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'No Observations Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start documenting your hiking adventures!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to a hike and add observations to track wildlife, views, or interesting moments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back to Hikes'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAllObservations,
        child: ListView.builder(
          itemCount: _observations.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final item = _observations[index];
            final obs = item.observation;
            final hike = item.hike;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HikeDetailsScreen(hike: hike),
                    ),
                  );
                  _loadAllObservations();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image if exists
                    if (obs.imagePath != null && obs.imagePath!.isNotEmpty)
                      ImagePreviewWidget(
                        imagePath: obs.imagePath,
                        height: 200,
                        showFullScreenOnTap: true,
                      ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hike name
                          Row(
                            children: [
                              Icon(
                                Icons.hiking,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hike.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Observation
                          Text(
                            obs.observation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(obs.time),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          // Coordinates if available
                          if (obs.hasCoordinates) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.gps_fixed,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    obs.coordinatesString,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Comments
                          if (obs.comments != null &&
                              obs.comments!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              obs.comments!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ObservationWithHike {
  final Observation observation;
  final Hike hike;

  ObservationWithHike({
    required this.observation,
    required this.hike,
  });
}