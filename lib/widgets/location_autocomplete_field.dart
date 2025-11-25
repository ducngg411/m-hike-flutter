import 'package:flutter/material.dart';
import 'dart:async';
import '../services/vietmap_service.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(PlaceSearchResult?) onLocationSelected;
  final IconData icon;

  const LocationAutocompleteField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onLocationSelected,
    this.icon = Icons.location_on,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;
  PlaceSearchResult? _selectedPlace;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Set searching state
    setState(() => _isSearching = true);

    // Debounce search by 500ms
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final results = await VietMapService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onPlaceSelected(PlaceSearchResult place) {
    setState(() {
      _selectedPlace = place;
      _controller.text = place.displayName;
      _searchResults = [];
      _focusNode.unfocus();
    });
    widget.onLocationSelected(place);
  }

  void _clearSelection() {
    setState(() {
      _selectedPlace = null;
      _controller.clear();
      _searchResults = [];
    });
    widget.onLocationSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Search for a location...',
            prefixIcon: Icon(widget.icon),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    place.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    place.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _onPlaceSelected(place),
                );
              },
            ),
          ),
        if (_selectedPlace != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPlace!.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Lat: ${_selectedPlace!.lat.toStringAsFixed(6)}, Lng: ${_selectedPlace!.lng.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
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

