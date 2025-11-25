import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import '../utils/image_helper.dart';
import '../widgets/image_preview_widget.dart';
import '../services/location_service.dart';

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
  late TextEditingController _locationController;
  late TextEditingController _dateController;
  late TextEditingController _lengthController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _equipmentController;

  bool _parkingAvailable = false;
  String _difficulty = 'Easy';
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  double? _latitude;  // THÊM MỚI
  double? _longitude; // THÊM MỚI
  bool _isGettingLocation = false; // THÊM MỚI

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
    _locationController = TextEditingController(text: widget.hike?.location ?? '');
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
      _latitude = widget.hike!.latitude;   // THÊM MỚI
      _longitude = widget.hike!.longitude; // THÊM MỚI
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
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

  // THÊM MỚI: Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      final locationData = await LocationService.getLocationWithAddress(context);

      if (locationData != null) {
        final Position position = locationData['position'];
        final String address = locationData['address'];

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;

          // Auto-fill location if empty
          if (_locationController.text.isEmpty) {
            _locationController.text = address;
          }

          _isGettingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location detected successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isGettingLocation = false);
      }
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // THÊM MỚI: Clear location
  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _saveHike() async {
    if (_formKey.currentState!.validate()) {
      final hike = Hike(
        id: widget.hike?.id,
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
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
        latitude: _latitude,   // THÊM MỚI
        longitude: _longitude, // THÊM MỚI
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

            // THÊM Location Section với GPS button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location *',
                      hintText: 'e.g., Wales, Kent',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: _isGettingLocation ? null : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.my_location),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        padding: const EdgeInsets.all(12),
                      ),
                      tooltip: 'Get current location',
                    ),
                    if (_latitude != null && _longitude != null)
                      IconButton(
                        onPressed: _clearLocation,
                        icon: const Icon(Icons.clear, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[100],
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: 'Clear location',
                      ),
                  ],
                ),
              ],
            ),

            // THÊM coordinates display
            if (_latitude != null && _longitude != null) ...[
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
                    const Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GPS Coordinates:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            LocationService.formatCoordinates(_latitude!, _longitude!),
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
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