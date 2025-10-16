import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive parking updates and alerts'),
            value: notificationsEnabled,
            onChanged: (bool value) {
              setState(() => notificationsEnabled = value);
            },
            activeThumbColor: Colors.blueAccent,
          ),

          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch app theme to dark mode'),
            value: widget.isDarkMode,
            onChanged: (bool value) {
              widget.onThemeChanged(value);
            },
          activeThumbColor: Colors.blueAccent,
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
    );
  }
}
