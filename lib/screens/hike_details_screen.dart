import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import '../models/observation.dart';
import 'add_hike_screen.dart';
import 'add_observation_screen.dart';
import '../widgets/image_preview_widget.dart';
import '../services/location_service.dart';
import '../services/share_service.dart';
import '../services/maps_service.dart';
import '../services/vietmap_service.dart';


class HikeDetailsScreen extends StatefulWidget {
  final Hike hike;

  const HikeDetailsScreen({super.key, required this.hike});

  @override
  State<HikeDetailsScreen> createState() => _HikeDetailsScreenState();
}

class _HikeDetailsScreenState extends State<HikeDetailsScreen> {
  late Hike _currentHike;
  List<Observation> _observations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentHike = widget.hike;
    _loadObservations();
  }

  Future<void> _loadObservations() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance
        .getObservationsForHike(_currentHike.id!);
    setState(() {
      _observations = data;
      _isLoading = false;
    });
  }

  // Fetch address from GPS coordinates using VietMap Reverse Geocoding
  Future<void> _fetchAddressFromGPS() async {
    if (!_currentHike.hasCoordinates) return;

    setState(() => _isLoading = true);

    try {
      final address = await VietMapService.getAddressFromCoordinates(
        latitude: _currentHike.latitude!,
        longitude: _currentHike.longitude!,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 8),
                Text('Address from GPS'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPS Coordinates:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentHike.coordinatesString,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Found Address:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Update location with found address
                  final updatedHike = _currentHike.copyWith(
                    location: address,
                  );
                  await DatabaseHelper.instance.updateHike(updatedHike);
                  setState(() => _currentHike = updatedHike);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location updated with address from GPS')),
                    );
                  }
                },
                child: const Text('Use This Address'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Allow user to add custom location name
  Future<void> _addCustomLocationName() async {
    final controller = TextEditingController(text: _currentHike.location);

    final customName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Location Name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentHike.hasCoordinates) ...[
              Text(
                'GPS Coordinates:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                _currentHike.coordinatesString,
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Hidden Valley Trail, Ba Vi Mountain',
                border: OutlineInputBorder(),
                helperText: 'Give this location a memorable name',
              ),
              autofocus: true,
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (customName != null && customName.isNotEmpty) {
      final updatedHike = _currentHike.copyWith(location: customName);
      await DatabaseHelper.instance.updateHike(updatedHike);
      setState(() => _currentHike = updatedHike);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location name updated')),
        );
      }
    }
  }

  Future<void> _editHike() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddHikeScreen(hike: _currentHike),
      ),
    );

    final updatedHike = await DatabaseHelper.instance.getHike(_currentHike.id!);
    if (updatedHike != null) {
      setState(() => _currentHike = updatedHike);
    }
  }

  Future<void> _deleteObservation(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Observation'),
        content: const Text('Are you sure you want to delete this observation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteObservation(id);
      _loadObservations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observation deleted')),
        );
      }
    }
  }

  // THÊM MỚI: Copy coordinates to clipboard
  void _copyCoordinates(double latitude, double longitude) {
    final coords = LocationService.formatCoordinates(latitude, longitude);
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordinates copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.blue),
              title: const Text('Share as Text'),
              subtitle: const Text('Share hike details with observations'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareHikeText(_currentHike, observations: _observations);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Share with Image'),
              subtitle: const Text('Include banner image'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareHikeWithImage(
                  _currentHike,
                  _currentHike.imagePath,
                  observations: _observations,
                );
              },
            ),
            if (_currentHike.hasCoordinates)
              ListTile(
                leading: const Icon(Icons.map, color: Colors.red),
                title: const Text('Share Location'),
                subtitle: const Text('Open in Google Maps'),
                onTap: () {
                  Navigator.pop(context);
                  final url = 'https://maps.google.com/?q=${_currentHike.latitude},${_currentHike.longitude}';
                  Share.share(
                    '📍 ${_currentHike.name}\n${_currentHike.location}\n\n$url',
                    subject: 'Hike Location',
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.grey),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroImage(),
            ),
            actions: [
              // Share Button
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareOptions(),
              ),

              // Edit Button
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editHike,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hike Details Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hike Details',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        _buildDetailRow(Icons.title, 'Hike Name', _currentHike.name),
                        _buildDetailRow(Icons.location_on, 'Location', _currentHike.location),

                        // THÊM GPS coordinates với copy button
                        if (_currentHike.hasCoordinates) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.gps_fixed, size: 20, color: Colors.green),
                                const SizedBox(width: 12),
                                const SizedBox(
                                  width: 100,
                                  child: Text(
                                    'GPS:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _copyCoordinates(
                                      _currentHike.latitude!,
                                      _currentHike.longitude!,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _currentHike.coordinatesString,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.copy,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action buttons for GPS location
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const SizedBox(width: 32),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : _fetchAddressFromGPS,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.search, size: 16),
                                  label: const Text(
                                    'Get Address',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _addCustomLocationName,
                                  icon: const Icon(Icons.edit_location_alt, size: 16),
                                  label: const Text(
                                    'Edit Name',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        _buildDetailRow(Icons.calendar_today, 'Date', _currentHike.date),
                        _buildDetailRow(
                          Icons.local_parking,
                          'Parking',
                          _currentHike.parkingAvailable ? 'Available' : 'Not Available',
                        ),
                        _buildDetailRow(Icons.straighten, 'Length', '${_currentHike.length} km'),
                        _buildDetailRow(Icons.trending_up, 'Difficulty', _currentHike.difficulty),
                        if (_currentHike.description != null)
                          _buildDetailRow(Icons.description, 'Description', _currentHike.description!),
                        if (_currentHike.estimatedDuration != null)
                          _buildDetailRow(Icons.timer, 'Duration', _currentHike.estimatedDuration!),
                        if (_currentHike.equipment != null)
                          _buildDetailRow(Icons.backpack, 'Equipment', _currentHike.equipment!),

                        // Directions Button
                        if (_currentHike.hasRouteInfo) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                MapsService.openDirections(
                                  context: context,
                                  startPlaceName: _currentHike.startPlaceName!,
                                  endPlaceName: _currentHike.endPlaceName!,
                                );
                              },
                              icon: const Icon(Icons.directions),
                              label: const Text('Get Directions'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Observations Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Observations (${_observations.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddObservationScreen(
                                hikeId: _currentHike.id!,
                              ),
                            ),
                          );
                          _loadObservations();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Observations List
                _isLoading
                    ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
                    : _observations.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No observations yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _observations.length,
                  itemBuilder: (context, index) {
                    return _buildObservationCard(_observations[index]);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    if (_currentHike.imagePath != null && _currentHike.imagePath!.isNotEmpty) {
      final file = File(_currentHike.imagePath!);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // THÊM GPS badge nếu có coordinates
            if (_currentHike.hasCoordinates)
              Positioned(
                top: 60,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gps_fixed, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'GPS Tracked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[400]!,
            Colors.green[700]!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.hiking,
          size: 80,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationCard(Observation obs) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image if exists
          if (obs.imagePath != null && obs.imagePath!.isNotEmpty)
            Stack(
              children: [
                ImagePreviewWidget(
                  imagePath: obs.imagePath,
                  height: 200,
                ),
                // THÊM GPS badge cho observation
                if (obs.hasCoordinates)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'GPS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Observation text
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
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
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

                // THÊM GPS coordinates cho observation
                if (obs.hasCoordinates) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _copyCoordinates(obs.latitude!, obs.longitude!),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            obs.coordinatesString,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy, size: 10, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],

                // Comments
                if (obs.comments != null && obs.comments!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    obs.comments!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],

                // Action buttons
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Share button
                    TextButton.icon(
                      onPressed: () {
                        ShareService.shareObservation(obs, _currentHike.name);
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                    ),

                    // Edit button
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddObservationScreen(
                              hikeId: _currentHike.id!,
                              observation: obs,
                            ),
                          ),
                        );
                        _loadObservations();
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteObservation(obs.id!),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoDateTime) {
    final dateTime = DateTime.parse(isoDateTime);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}