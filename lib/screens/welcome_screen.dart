import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomePageData> _pages = [
    WelcomePageData(
      title: 'Welcome to M-Hike',
      description: 'Your ultimate companion for planning and tracking hiking adventures',
      icon: Icons.hiking,
      color: Colors.green,
    ),
    WelcomePageData(
      title: 'Plan Your Hikes',
      description: 'Record details of your hiking plans including location, difficulty, and length',
      icon: Icons.map,
      color: Colors.blue,
    ),
    WelcomePageData(
      title: 'Track Observations',
      description: 'Document wildlife sightings, weather conditions, and memorable moments during your hikes',
      icon: Icons.photo_camera,
      color: Colors.orange,
    ),
    WelcomePageData(
      title: 'Search & Organize',
      description: 'Easily find and manage all your hiking records in one place',
      icon: Icons.search,
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  void _skipWelcome() {
    _completeWelcome();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipWelcome,
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildWelcomePage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                    (index) => _buildPageIndicator(index == _currentPage),
              ),
            ),
            const SizedBox(height: 32),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(WelcomePageData data) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data.icon,
            size: 120,
            color: data.color,
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].color : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WelcomePageData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  WelcomePageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}