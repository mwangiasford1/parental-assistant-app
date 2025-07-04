// features/home/profile_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = widget.user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _currentRole = user.role;
    } else {
      // Load from AuthService if no user passed
      final uid = AuthService.currentUserId;
      if (uid != null) {
        print('[UI] About to fetch user profile for $uid in ProfileScreen');
        final userProfile = await AuthService.getUserProfile(uid);
        if (userProfile != null) {
          _nameController.text = userProfile.name;
          _emailController.text = userProfile.email;
          _currentRole = userProfile.role;
        }
      }
    }
    setState(() {});
  }

  Future<void> _updateProfile() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = AuthService.currentUserId;
      if (uid != null) {
        await AuthService.updateUserProfile(uid, {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
        });

        // Update display name in Firebase Auth
        await AuthService.updateDisplayName(_nameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;
    final userEmail = widget.user?.email;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrent ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => showCurrent = !showCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => showNew = !showNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: userEmail == null
                        ? null
                        : () async {
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: userEmail);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset email sent. Check your inbox.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error sending reset email: $e',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Forgot Password?'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters.'),
                    ),
                  );
                  return;
                }
                try {
                  // In a real app, you would re-authenticate the user first
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password change requested. Check your email for confirmation.',
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error changing password: $e')),
                  );
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.deleteAccount();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _loadUserData(); // Reset to original values
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading:
                      user.profileImageUrl != null &&
                          user.profileImageUrl!.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user.profileImageUrl!),
                        )
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Text('Role: ${user.role}'),
                      Text('Points: ${user.points}'),
                    ],
                  ),
                ),
              ),
            ],
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary,
                    backgroundImage: widget.user?.profileImageUrl != null
                        ? NetworkImage(widget.user!.profileImageUrl!)
                        : null,
                    child: widget.user?.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image picker coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Display (Read-only)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.work, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            'Role: ${_currentRole?.toUpperCase() ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _updateProfile,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save Changes'),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              child: const Text('Edit Profile'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Security Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your account password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _changePassword,
                    ),

                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Two-Factor Authentication'),
                      subtitle: const Text('Add an extra layer of security'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Two-factor authentication coming soon!',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Account Actions
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _changePassword,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.orange.shade700),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.orange.shade700,
                    ),
                    onTap: _logout,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.red,
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
