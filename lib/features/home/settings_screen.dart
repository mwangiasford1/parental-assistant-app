// features/home/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/settings_provider.dart';
import '../../core/theme.dart';
import '../home/theme_picker_screen.dart';
import '../home/content_filtering_screen.dart';
import '../home/profile_screen.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel? user;
  const SettingsScreen({super.key, this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // GENERAL SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'General',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleDarkMode(val),
          ),
          ListTile(
            title: const Text('Theme Picker'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (user != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ThemePickerScreen(user: user),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not loaded.')),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Font Size'),
            subtitle: Slider(
              value: settingsProvider.fontSize,
              min: 12,
              max: 28,
              divisions: 8,
              label: settingsProvider.fontSize.round().toString(),
              onChanged: (v) => settingsProvider.setFontSize(v),
            ),
          ),
          SwitchListTile(
            title: const Text('High Contrast Mode'),
            value: settingsProvider.highContrast,
            onChanged: (val) => settingsProvider.setHighContrast(val),
          ),

          // CONTENT & PARENTAL CONTROLS SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Content & Parental Controls',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Content Filtering'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ContentFilteringScreen(),
                ),
              );
            },
          ),
          // Add more parental controls as needed

          // ACCOUNT & SECURITY SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Account & Security',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Open change password dialog from ProfileScreen logic
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Change Password'),
                  content: const Text(
                    'Change password is available in the Profile screen.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Coming soon!'),
            trailing: const Icon(Icons.lock),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication coming soon!'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Delete Account'),
            trailing: const Icon(Icons.delete, color: Colors.red),
            onTap: () {
              // Open delete account dialog from ProfileScreen logic
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Delete account is available in the Profile screen.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            trailing: const Icon(Icons.logout),
            onTap: () async {
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
