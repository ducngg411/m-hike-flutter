import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import 'welcome_screen.dart';
import 'statistics_screen.dart'; // THÊM import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _resetWelcomeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome screen reset')),
      );
    }
  }

  Future<void> _showWelcomeScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'Are you sure you want to delete all hikes and observations? '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteAllHikes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted')),
        );
      }
    }
  }

  Future<void> _showAboutDialog() async {
    showAboutDialog(
      context: context,
      applicationName: 'M-Hike',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.hiking, size: 48),
      children: [
        const Text(
          'A cross-platform mobile application for managing hiking trips and observations.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Developed for COMP1786 - Mobile Application Design and Development',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // General Section
          const ListTile(
            title: Text(
              'GENERAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // THÊM Statistics menu item
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: Colors.blue),
            title: const Text('Statistics'),
            subtitle: const Text('View your hiking statistics and charts'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('View Welcome Screen'),
            subtitle: const Text('Show the app introduction'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showWelcomeScreen,
          ),

          const Divider(height: 1),

          // Data Section
          const ListTile(
            title: Text(
              'DATA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete All Data'),
            subtitle: const Text('Remove all hikes and observations'),
            onTap: _deleteAllData,
          ),

          const Divider(height: 1),

          // About Section
          const ListTile(
            title: Text(
              'ABOUT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About M-Hike'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAboutDialog,
          ),

          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Technology'),
            subtitle: const Text('Flutter & Dart'),
          ),

          const Divider(height: 1),

          // Footer
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'M-Hike - Your Hiking Companion\n'
                  'COMP1786 Coursework\n\n'
                  'Features:\n'
                  '• GPS Location Tracking\n'
                  '• Photo Integration\n'
                  '• Advanced Search\n'
                  '• Statistics & Analytics\n'
                  '• Social Sharing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}