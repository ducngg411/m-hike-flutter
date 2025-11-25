import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import '../utils/image_helper.dart';
import '../widgets/image_preview_widget.dart';
import '../services/location_service.dart';
import '../services/vietmap_service.dart';
import '../widgets/location_autocomplete_field.dart';

class AddHikeScreen extends StatefulWidget {
  final Hike? hike;

  const AddHikeScreen({super.key, this.hike});

  @override
  State<AddHikeScreen> createState() => _AddHikeScreenState();
}

class _AddHikeScreenState extends State<AddHikeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _startPointController;
  late TextEditingController _endPointController;
  late TextEditingController _dateController;
  late TextEditingController _lengthController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _equipmentController;

  bool _parkingAvailable = false;
  String _difficulty = 'Easy';
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  double? _latitude;
  double? _longitude;

  // VietMap route planning with new flow
  List<PlaceSearchResult> _startSuggestions = [];
  List<PlaceSearchResult> _endSuggestions = [];
  PlaceDetails? _selectedStart;
  PlaceDetails? _selectedEnd;
  bool _isCalculatingRoute = false;

  final List<String> _difficultyLevels = [
    'Easy',
    'Moderate',
    'Difficult',
    'Very Difficult',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.hike?.name ?? '');

    // Parse location if editing existing hike (format: "Start → End")
    String startText = '';
    String endText = '';
    if (widget.hike?.location != null && widget.hike!.location.contains('→')) {
      final parts = widget.hike!.location.split('→');
      startText = parts[0].trim();
      endText = parts.length > 1 ? parts[1].trim() : '';
    } else if (widget.hike?.location != null) {
      startText = widget.hike!.location;
    }

    _startPointController = TextEditingController(text: startText);
    _endPointController = TextEditingController(text: endText);
    _dateController = TextEditingController(
      text: widget.hike?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _lengthController = TextEditingController(
      text: widget.hike?.length.toString() ?? '',
    );
    _descriptionController = TextEditingController(text: widget.hike?.description ?? '');
    _durationController = TextEditingController(text: widget.hike?.estimatedDuration ?? '');
    _equipmentController = TextEditingController(text: widget.hike?.equipment ?? '');

    if (widget.hike != null) {
      _parkingAvailable = widget.hike!.parkingAvailable;
      _difficulty = widget.hike!.difficulty;
      _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.hike!.date);
      _imagePath = widget.hike!.imagePath;
      _latitude = widget.hike!.latitude;
      _longitude = widget.hike!.longitude;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startPointController.dispose();
    _endPointController.dispose();
    _dateController.dispose();
    _lengthController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final imagePath = await ImageHelper.showImageSourceDialog(context);
    if (imagePath != null) {
      setState(() {
        _imagePath = imagePath;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }



  // Search for start location using Autocomplete API
  Future<void> _searchStartLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _startSuggestions = []);
      return;
    }

    final results = await VietMapService.searchPlaces(query);
    setState(() => _startSuggestions = results);
  }

  // Search for end location using Autocomplete API
  Future<void> _searchEndLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _endSuggestions = []);
      return;
    }

    final results = await VietMapService.searchPlaces(query);
    setState(() => _endSuggestions = results);
  }

  // Select start location and fetch exact coordinates using Place API v3
  Future<void> _selectStartLocation(PlaceSearchResult result) async {
    if (result.placeId == null) return;

    setState(() => _isCalculatingRoute = true);

    // Call Place API v3 to get exact coordinates
    final details = await VietMapService.getPlaceDetails(result.placeId!);

    setState(() {
      _selectedStart = details;
      _startPointController.text = details?.display ?? result.displayName;
      _startSuggestions = [];
      _isCalculatingRoute = false;
    });

    print('✓ Selected start: ${details?.display}, Lat: ${details?.lat}, Lng: ${details?.lng}');

    // Auto-calculate route if both points are selected
    if (_selectedStart != null && _selectedEnd != null) {
      _calculateRouteDistance();
    }
  }

  // Select end location and fetch exact coordinates using Place API v3
  Future<void> _selectEndLocation(PlaceSearchResult result) async {
    if (result.placeId == null) return;

    setState(() => _isCalculatingRoute = true);

    // Call Place API v3 to get exact coordinates
    final details = await VietMapService.getPlaceDetails(result.placeId!);

    setState(() {
      _selectedEnd = details;
      _endPointController.text = details?.display ?? result.displayName;
      _endSuggestions = [];
      _isCalculatingRoute = false;
    });

    print('✓ Selected end: ${details?.display}, Lat: ${details?.lat}, Lng: ${details?.lng}');

    // Auto-calculate route if both points are selected
    if (_selectedStart != null && _selectedEnd != null) {
      _calculateRouteDistance();
    }
  }

  // Calculate route distance using Route API v3
  Future<void> _calculateRouteDistance() async {
    if (_selectedStart == null || _selectedEnd == null) return;

    setState(() => _isCalculatingRoute = true);

    try {
      final route = await VietMapService.calculateRoute(
        startLat: _selectedStart!.lat,
        startLng: _selectedStart!.lng,
        endLat: _selectedEnd!.lat,
        endLng: _selectedEnd!.lng,
        vehicle: 'car',
        pointsEncoded: false,
      );

      if (route != null && mounted) {
        setState(() {
          _lengthController.text = route.distanceKm.toStringAsFixed(2);
          _isCalculatingRoute = false;


          // Set coordinates to start point
          _latitude = _selectedStart!.lat;
          _longitude = _selectedStart!.lng;

          // Auto-fill duration if available
          if (route.durationMinutes > 0 && _durationController.text.isEmpty) {
            final hours = route.durationMinutes ~/ 60;
            final minutes = route.durationMinutes % 60;
            if (hours > 0) {
              _durationController.text = '${hours}h ${minutes}m';
            } else {
              _durationController.text = '${minutes}m';
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route calculated: ${route.distanceKm.toStringAsFixed(2)} km'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _isCalculatingRoute = false);
      }
    } catch (e) {
      setState(() => _isCalculatingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating route: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Clear route planner
  void _clearRoutePlanner() {
    setState(() {
      _selectedStart = null;
      _selectedEnd = null;
      _startSuggestions = [];
      _endSuggestions = [];
    });
  }

  Future<void> _saveHike() async {
    if (_formKey.currentState!.validate()) {
      // Validate start and end points
      if (_startPointController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a start point'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_endPointController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an end point'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Build location string from start and end points
      String location = '${_startPointController.text.trim()} → ${_endPointController.text.trim()}';

      final hike = Hike(
        id: widget.hike?.id,
        name: _nameController.text.trim(),
        location: location,
        date: _dateController.text,
        parkingAvailable: _parkingAvailable,
        length: double.parse(_lengthController.text),
        difficulty: _difficulty,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        estimatedDuration: _durationController.text.trim().isEmpty
            ? null
            : _durationController.text.trim(),
        equipment: _equipmentController.text.trim().isEmpty
            ? null
            : _equipmentController.text.trim(),
        imagePath: _imagePath,
        latitude: _latitude,
        longitude: _longitude,
        startPlaceName: _startPointController.text.trim(),
        endPlaceName: _endPointController.text.trim(),
      );

      final confirmed = await _showConfirmationDialog(hike);

      if (confirmed == true) {
        if (widget.hike == null) {
          await DatabaseHelper.instance.createHike(hike);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hike added successfully')),
            );
          }
        } else {
          await DatabaseHelper.instance.updateHike(hike);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hike updated successfully')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog(Hike hike) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hike.imagePath != null) ...[
                ImagePreviewWidget(
                  imagePath: hike.imagePath,
                  height: 150,
                  showFullScreenOnTap: false,
                ),
                const SizedBox(height: 16),
              ],
              _buildConfirmationRow('Name', hike.name),
              _buildConfirmationRow('Location', hike.location),
              // THÊM coordinates trong confirmation
              if (hike.hasCoordinates)
                _buildConfirmationRow('Coordinates', hike.coordinatesString),
              _buildConfirmationRow('Date', hike.date),
              _buildConfirmationRow('Parking', hike.parkingAvailable ? 'Yes' : 'No'),
              _buildConfirmationRow('Length', '${hike.length} km'),
              _buildConfirmationRow('Difficulty', hike.difficulty),
              if (hike.description != null)
                _buildConfirmationRow('Description', hike.description!),
              if (hike.estimatedDuration != null)
                _buildConfirmationRow('Duration', hike.estimatedDuration!),
              if (hike.equipment != null)
                _buildConfirmationRow('Equipment', hike.equipment!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hike == null ? 'Add Hike' : 'Edit Hike'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Section
            const Text(
              'Hike Banner Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_imagePath != null) ...[
              Stack(
                children: [
                  ImagePreviewWidget(
                    imagePath: _imagePath,
                    height: 200,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _removeImage,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add banner image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Name (Required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Hike Name *',
                hintText: 'e.g., Snowdon, Trosley Country Park',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter hike name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Start Point (Required)
            const Text(
              'Start Point *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _startPointController,
              decoration: const InputDecoration(
                hintText: 'Search start location...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.green),
              ),
              onChanged: _searchStartLocation,
            ),
            if (_startSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _startSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _startSuggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(suggestion.displayName),
                      subtitle: Text(
                        suggestion.address,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _selectStartLocation(suggestion),
                    );
                  },
                ),
              ),
            ],
            if (_selectedStart != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStart!.display,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedStart!.lat.toStringAsFixed(6)}, ${_selectedStart!.lng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() {
                        _selectedStart = null;
                        _startPointController.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // End Point (Required)
            const Text(
              'End Point *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _endPointController,
              decoration: const InputDecoration(
                hintText: 'Search end location...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on, color: Colors.red),
              ),
              onChanged: _searchEndLocation,
            ),
            if (_endSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _endSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _endSuggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(suggestion.displayName),
                      subtitle: Text(
                        suggestion.address,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () => _selectEndLocation(suggestion),
                    );
                  },
                ),
              ),
            ],
            if (_selectedEnd != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedEnd!.display,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_selectedEnd!.lat.toStringAsFixed(6)}, ${_selectedEnd!.lng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() {
                        _selectedEnd = null;
                        _endPointController.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ],

            if (_isCalculatingRoute) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Calculating route...'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Date (Required)
            TextFormField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectDate,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Parking Available (Required)
            Card(
              child: SwitchListTile(
                title: const Text('Parking Available *'),
                value: _parkingAvailable,
                onChanged: (value) {
                  setState(() => _parkingAvailable = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Length (Required)
            TextFormField(
              controller: _lengthController,
              decoration: const InputDecoration(
                labelText: 'Length (km) *',
                hintText: 'e.g., 5.5',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter length';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Length must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Difficulty (Required)
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty Level *',
                border: OutlineInputBorder(),
              ),
              items: _difficultyLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _difficulty = newValue);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description (Optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief description of the hike',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Estimated Duration (Optional)
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Estimated Duration (Optional)',
                hintText: 'e.g., 3-4 hours',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Equipment Needed (Optional)
            TextFormField(
              controller: _equipmentController,
              decoration: const InputDecoration(
                labelText: 'Equipment Needed (Optional)',
                hintText: 'e.g., Hiking boots, water, map',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveHike,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                widget.hike == null ? 'Add Hike' : 'Update Hike',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              '* Required fields',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}