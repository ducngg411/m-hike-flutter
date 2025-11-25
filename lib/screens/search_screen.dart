import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import 'hike_details_screen.dart';
import 'advanced_search_screen.dart'; // Thêm import

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Hike> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await DatabaseHelper.instance
        .searchHikesByName(_searchController.text.trim());

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Hikes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Thêm nút Advanced Search
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedSearchScreen(),
                ),
              );
            },
            tooltip: 'Advanced Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search by name',
                          hintText: 'Enter hike name',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show/hide clear button
                        },
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _performSearch,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Thêm hint cho Advanced Search
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdvancedSearchScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Advanced Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Search for hikes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a hike name or use advanced search',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : _searchResults.isEmpty
                ? Center(
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
                    'Try a different search term',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final hike = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      hike.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${hike.location} • ${hike.date}\n'
                          'Length: ${hike.length}km • ${hike.difficulty}',
                    ),
                    isThreeLine: true,
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
      ),
    );
  }
}