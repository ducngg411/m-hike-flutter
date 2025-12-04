import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import 'hike_details_screen.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _formKey = GlobalKey<FormState>();

  // Search criteria controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _minLengthController = TextEditingController();
  final _maxLengthController = TextEditingController();

  String _selectedDifficulty = 'All';
  String? _selectedParkingFilter;

  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Hike> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showFilters = true;

  List<String> _availableLocations = [];
  List<String> _availableDifficulties = ['All'];

  final List<String> _parkingOptions = ['All', 'Available', 'Not Available'];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _minLengthController.dispose();
    _maxLengthController.dispose();
    super.dispose();
  }

  Future<void> _loadFilterOptions() async {
    final locations = await DatabaseHelper.instance.getAllLocations();
    final difficulties = await DatabaseHelper.instance.getAllDifficulties();

    setState(() {
      _availableLocations = locations;
      _availableDifficulties = ['All', ...difficulties];
    });
  }

  Future<void> _selectDate(bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _dateFrom = picked;
          _dateFromController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _dateTo = picked;
          _dateToController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _performSearch() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSearching = true;
        _hasSearched = true;
      });

      // Parse length values
      double? minLength;
      double? maxLength;

      if (_minLengthController.text.isNotEmpty) {
        minLength = double.tryParse(_minLengthController.text);
      }
      if (_maxLengthController.text.isNotEmpty) {
        maxLength = double.tryParse(_maxLengthController.text);
      }

      // Parse parking filter
      bool? parkingAvailable;
      if (_selectedParkingFilter == 'Available') {
        parkingAvailable = true;
      } else if (_selectedParkingFilter == 'Not Available') {
        parkingAvailable = false;
      }

      final results = await DatabaseHelper.instance.advancedSearch(
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        dateFrom: _dateFromController.text.isEmpty
            ? null
            : _dateFromController.text,
        dateTo: _dateToController.text.isEmpty
            ? null
            : _dateToController.text,
        minLength: minLength,
        maxLength: maxLength,
        difficulty: _selectedDifficulty == 'All'
            ? null
            : _selectedDifficulty,
        parkingAvailable: parkingAvailable,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showFilters = false; // Collapse filters after search
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _nameController.clear();
      _locationController.clear();
      _dateFromController.clear();
      _dateToController.clear();
      _minLengthController.clear();
      _maxLengthController.clear();
      _selectedDifficulty = 'All';
      _selectedParkingFilter = null;
      _dateFrom = null;
      _dateTo = null;
      _searchResults = [];
      _hasSearched = false;
      _showFilters = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_hasSearched)
            IconButton(
              icon: Icon(_showFilters
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down),
              onPressed: () {
                setState(() => _showFilters = !_showFilters);
              },
              tooltip: _showFilters ? 'Hide Filters' : 'Show Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Filters
          if (_showFilters)
            Expanded(
              flex: _hasSearched ? 1 : 1,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Basic Search Section
                    _buildSectionHeader('Basic Search'),
                    const SizedBox(height: 8),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Hike Name',
                        hintText: 'Enter hike name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.hiking),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location with autocomplete
                    _availableLocations.isEmpty
                        ? TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Enter location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    )
                        : Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _availableLocations.where((String option) {
                          return option.toLowerCase().contains(
                              textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _locationController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode,
                          onFieldSubmitted) {
                        _locationController.text = controller.text;
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Enter or select location',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Date Range Section
                    _buildSectionHeader('Date Range'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateFromController,
                            decoration: const InputDecoration(
                              labelText: 'From Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _dateToController,
                            decoration: const InputDecoration(
                              labelText: 'To Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(false),
                            validator: (value) {
                              if (_dateFrom != null && _dateTo != null) {
                                if (_dateTo!.isBefore(_dateFrom!)) {
                                  return 'To date must be after from date';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Length Range Section
                    _buildSectionHeader('Length Range (km)'),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minLengthController,
                            decoration: const InputDecoration(
                              labelText: 'Min Length',
                              border: OutlineInputBorder(),
                              suffixText: 'km',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxLengthController,
                            decoration: const InputDecoration(
                              labelText: 'Max Length',
                              border: OutlineInputBorder(),
                              suffixText: 'km',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final max = double.tryParse(value);
                                if (max == null) {
                                  return 'Invalid number';
                                }
                                if (_minLengthController.text.isNotEmpty) {
                                  final min = double.tryParse(
                                      _minLengthController.text);
                                  if (min != null && max < min) {
                                    return 'Max must be > min';
                                  }
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Difficulty Section
                    _buildSectionHeader('Difficulty'),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                      items: _availableDifficulties.map((String difficulty) {
                        return DropdownMenuItem<String>(
                          value: difficulty,
                          child: Text(difficulty),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedDifficulty = newValue);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Parking Section
                    _buildSectionHeader('Parking Availability'),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: _selectedParkingFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_parking),
                        hintText: 'All',
                      ),
                      items: _parkingOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option == 'All' ? null : option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedParkingFilter = newValue);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _performSearch,
                            icon: const Icon(Icons.search),
                            label: const Text('Search'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Search Results
          if (_hasSearched && !_showFilters)
            Expanded(
              child: _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return const SizedBox.shrink();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hikes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _showFilters = true);
                },
                icon: const Icon(Icons.filter_alt, size: 18),
                label: const Text('Refine'),
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final hike = _searchResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    hike.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(hike.location)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(hike.date),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.straighten,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${hike.length} km'),
                          const SizedBox(width: 16),
                          const Icon(Icons.trending_up,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(hike.difficulty),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HikeDetailsScreen(hike: hike),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}