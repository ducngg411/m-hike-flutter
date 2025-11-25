import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../database/database_helper.dart';
import '../models/observation.dart';
import '../utils/image_helper.dart';
import '../widgets/image_preview_widget.dart';
import '../services/location_service.dart';

class AddObservationScreen extends StatefulWidget {
  final int hikeId;
  final Observation? observation;

  const AddObservationScreen({
    super.key,
    required this.hikeId,
    this.observation,
  });

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _observationController;
  late TextEditingController _timeController;
  late TextEditingController _commentsController;

  DateTime _selectedDateTime = DateTime.now();
  String? _imagePath;
  double? _latitude;  // THÊM MỚI
  double? _longitude; // THÊM MỚI
  bool _isGettingLocation = false; // THÊM MỚI

  @override
  void initState() {
    super.initState();

    _observationController = TextEditingController(
      text: widget.observation?.observation ?? '',
    );
    _commentsController = TextEditingController(
      text: widget.observation?.comments ?? '',
    );

    if (widget.observation != null) {
      _selectedDateTime = DateTime.parse(widget.observation!.time);
      _imagePath = widget.observation!.imagePath;
      _latitude = widget.observation!.latitude;   // THÊM MỚI
      _longitude = widget.observation!.longitude; // THÊM MỚI
    }

    _timeController = TextEditingController(
      text: _formatDateTime(_selectedDateTime),
    );
  }

  @override
  void dispose() {
    _observationController.dispose();
    _timeController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _timeController.text = _formatDateTime(_selectedDateTime);
    });
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

        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _isGettingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location captured successfully'),
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

  Future<void> _saveObservation() async {
    if (_formKey.currentState!.validate()) {
      final observation = Observation(
        id: widget.observation?.id,
        hikeId: widget.hikeId,
        observation: _observationController.text.trim(),
        time: _selectedDateTime.toIso8601String(),
        comments: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
        imagePath: _imagePath,
        latitude: _latitude,   // THÊM MỚI
        longitude: _longitude, // THÊM MỚI
      );

      if (widget.observation == null) {
        await DatabaseHelper.instance.createObservation(observation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observation added successfully')),
          );
        }
      } else {
        await DatabaseHelper.instance.updateObservation(observation);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observation updated successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.observation == null
            ? 'Add Observation'
            : 'Edit Observation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Section
            const Text(
              'Observation Photo',
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
                    height: 250,
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.edit),
                label: const Text('Change Photo'),
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
                        Icons.add_a_photo,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Observation (Required)
            TextFormField(
              controller: _observationController,
              decoration: const InputDecoration(
                labelText: 'Observation *',
                hintText: 'e.g., Spotted a deer, Beautiful view',
                border: OutlineInputBorder(),
                helperText: 'Describe what you observed',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter observation';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Time (Required)
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time *',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
                helperText: 'Date and time of observation',
              ),
              readOnly: true,
              onTap: _selectDateTime,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select time';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // THÊM MỚI: GPS Location Section
            Row(
              children: [
                Expanded(
                  child: Text(
                    'GPS Location (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_latitude != null ? 'Update' : 'Capture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // THÊM coordinates display
            if (_latitude != null && _longitude != null) ...[
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
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clearLocation,
                      color: Colors.red,
                      tooltip: 'Clear location',
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No GPS location captured',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Additional Comments (Optional)
            TextFormField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Additional Comments (Optional)',
                hintText: 'Any additional details',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveObservation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                widget.observation == null
                    ? 'Add Observation'
                    : 'Update Observation',
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