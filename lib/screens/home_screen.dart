import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/hike.dart';
import '../services/share_service.dart';
import 'add_hike_screen.dart';
import 'hike_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortFilter {
  newest,
  oldest,
  recent7Days,
  recent30Days,
  nameAZ,
  namZA,
}

class _HomeScreenState extends State<HomeScreen> {
  List<Hike> hikes = [];
  List<Hike> filteredHikes = [];
  bool isLoading = false;
  SortFilter currentFilter = SortFilter.newest;
  Map<int, int> observationCounts = {}; // Map hikeId -> observation count

  @override
  void initState() {
    super.initState();
    _loadHikes();
  }

  Future<void> _loadHikes() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.getAllHikes();

    // Load observation counts for each hike
    final Map<int, int> counts = {};
    for (var hike in data) {
      if (hike.id != null) {
        final observations = await DatabaseHelper.instance.getObservationsForHike(hike.id!);
        counts[hike.id!] = observations.length;
      }
    }

    setState(() {
      hikes = data;
      observationCounts = counts;
      _applyFilter();
      isLoading = false;
    });
  }

  void _applyFilter() {
    List<Hike> result = List.from(hikes);
    final now = DateTime.now();

    switch (currentFilter) {
      case SortFilter.newest:
        // Sort by creation date (assuming id is auto-increment, newer = higher id)
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case SortFilter.oldest:
        result.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
        break;
      case SortFilter.recent7Days:
        result = result.where((hike) {
          final hikeDate = DateTime.parse(hike.date);
          final difference = now.difference(hikeDate).inDays;
          return difference <= 7;
        }).toList();
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case SortFilter.recent30Days:
        result = result.where((hike) {
          final hikeDate = DateTime.parse(hike.date);
          final difference = now.difference(hikeDate).inDays;
          return difference <= 30;
        }).toList();
        result.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case SortFilter.nameAZ:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortFilter.namZA:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }

    filteredHikes = result;
  }

  void _changeFilter(SortFilter newFilter) {
    setState(() {
      currentFilter = newFilter;
      _applyFilter();
    });
  }

  String _getFilterLabel(SortFilter filter) {
    switch (filter) {
      case SortFilter.newest:
        return 'Newest First';
      case SortFilter.oldest:
        return 'Oldest First';
      case SortFilter.recent7Days:
        return 'Last 7 Days';
      case SortFilter.recent30Days:
        return 'Last 30 Days';
      case SortFilter.nameAZ:
        return 'Name (A-Z)';
      case SortFilter.namZA:
        return 'Name (Z-A)';
    }
  }

  IconData _getFilterIcon(SortFilter filter) {
    switch (filter) {
      case SortFilter.newest:
        return Icons.new_releases;
      case SortFilter.oldest:
        return Icons.history;
      case SortFilter.recent7Days:
        return Icons.date_range;
      case SortFilter.recent30Days:
        return Icons.calendar_month;
      case SortFilter.nameAZ:
        return Icons.sort_by_alpha;
      case SortFilter.namZA:
        return Icons.sort_by_alpha;
    }
  }

  Future<void> _deleteHike(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hike'),
        content: const Text('Are you sure you want to delete this hike?'),
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
      await DatabaseHelper.instance.deleteHike(id);
      _loadHikes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hike deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Hike'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<SortFilter>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Sort & Filter',
            onSelected: _changeFilter,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: SortFilter.newest,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.newest), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.newest)),
                    if (currentFilter == SortFilter.newest)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.oldest,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.oldest), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.oldest)),
                    if (currentFilter == SortFilter.oldest)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: SortFilter.recent7Days,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.recent7Days), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.recent7Days)),
                    if (currentFilter == SortFilter.recent7Days)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.recent30Days,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.recent30Days), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.recent30Days)),
                    if (currentFilter == SortFilter.recent30Days)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: SortFilter.nameAZ,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.nameAZ), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.nameAZ)),
                    if (currentFilter == SortFilter.nameAZ)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: SortFilter.namZA,
                child: Row(
                  children: [
                    Icon(_getFilterIcon(SortFilter.namZA), size: 20),
                    const SizedBox(width: 12),
                    Text(_getFilterLabel(SortFilter.namZA)),
                    if (currentFilter == SortFilter.namZA)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 20, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHikes,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hikes.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hiking,
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
                'Tap the + button to add your first hike',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // Quick Filter Chips
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildQuickFilterChip(SortFilter.newest),
                  _buildQuickFilterChip(SortFilter.recent7Days),
                  _buildQuickFilterChip(SortFilter.recent30Days),
                  _buildQuickFilterChip(SortFilter.nameAZ),
                ],
              ),
            ),
            // Hikes count and current filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${filteredHikes.length} ${filteredHikes.length == 1 ? 'hike' : 'hikes'}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getFilterLabel(currentFilter),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hikes List
            Expanded(
              child: filteredHikes.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_alt_off,
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
                      'Try changing the filter',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: filteredHikes.length,
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemBuilder: (context, index) {
                  final hike = filteredHikes[index];
                  return _buildHikeCard(hike);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddHikeScreen()),
              );
              _loadHikes();
            },
            tooltip: 'Add Hike',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(SortFilter filter) {
    final isSelected = currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(_getFilterLabel(filter)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _changeFilter(filter);
          }
        },
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Widget _buildHikeCard(Hike hike) {
    final observationCount = observationCounts[hike.id] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HikeDetailsScreen(hike: hike),
            ),
          );
          _loadHikes();
        },
        onLongPress: () {
          _showQuickActions(hike);
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Image
                if (hike.imagePath != null && hike.imagePath!.isNotEmpty)
                  _buildBannerImage(hike.imagePath!)
                else
                  _buildPlaceholderBanner(),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hike.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHike(hike.id!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(hike.location)),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(hike.date),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatChip(
                        Icons.straighten,
                        '${hike.length} km',
                        Colors.blue,
                      ),
                      _buildStatChip(
                        _getDifficultyIcon(hike.difficulty),
                        hike.difficulty,
                        _getDifficultyColor(hike.difficulty),
                      ),
                      _buildStatChip(
                        Icons.local_parking,
                        hike.parkingAvailable ? 'Parking' : 'No Parking',
                        hike.parkingAvailable ? Colors.green : Colors.red,
                      ),
                      // GPS badge
                      if (hike.hasCoordinates)
                        _buildStatChip(
                          Icons.gps_fixed,
                          'GPS',
                          Colors.purple,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // Ribbon badge for observation count
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.teal[600]!,
                  Colors.teal[400]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.note_alt,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$observationCount ${observationCount == 1 ? 'observation' : 'observations'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

  Widget _buildBannerImage(String imagePath) {
    final file = File(imagePath);

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: file.existsSync()
          ? Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderBanner();
        },
      )
          : _buildPlaceholderBanner(),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[300]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.hiking,
          size: 64,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'difficult':
      case 'very difficult':
        return Icons.sentiment_dissatisfied;
      case 'expert':
        return Icons.warning;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'difficult':
        return Colors.red;
      case 'very difficult':
        return Colors.red[900]!;
      case 'expert':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showQuickActions(Hike hike) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareHikeWithImage(hike, hike.imagePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('Edit'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddHikeScreen(hike: hike),
                  ),
                );
                _loadHikes();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteHike(hike.id!);
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
}