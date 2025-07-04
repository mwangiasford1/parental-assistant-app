// features/home/password_backup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/password_model.dart';
import '../../services/password_service.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';

class PasswordBackupScreen extends StatefulWidget {
  final UserModel? user;

  const PasswordBackupScreen({super.key, this.user});

  @override
  State<PasswordBackupScreen> createState() => _PasswordBackupScreenState();
}

class _PasswordBackupScreenState extends State<PasswordBackupScreen> {
  String get userId =>
      widget.user?.uid ?? AuthService.currentUserId ?? 'demoUser';
  String selectedCategory = 'All';
  String searchQuery = '';
  bool showPassword = false;
  bool isLoading = false;

  void _showAddPasswordDialog() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final websiteController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'General';
    bool showPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Netflix Account',
                  ),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username/Email',
                    hintText: 'Enter username or email',
                  ),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setDialogState(
                            () => showPassword = !showPassword,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            final generatedPassword =
                                PasswordService.generatePassword();
                            passwordController.text = generatedPassword;
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    hintText: 'e.g., https://netflix.com',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: PasswordCategories.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(
                            PasswordCategories.categoryIcons[category] ?? '📁',
                          ),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => selectedCategory = value ?? 'General',
                ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional notes about this password',
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
                if (titleController.text.trim().isEmpty ||
                    usernameController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  await PasswordService.addPassword(
                    userId: userId,
                    title: titleController.text.trim(),
                    username: usernameController.text.trim(),
                    password: passwordController.text.trim(),
                    category: selectedCategory,
                    website: websiteController.text.trim().isEmpty
                        ? null
                        : websiteController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password added successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding password: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDetails(PasswordModel password) {
    final decryptedPassword = PasswordService.decryptPassword(
      password.encryptedPassword,
    );
    final strength = PasswordService.getPasswordStrength(decryptedPassword);
    final strengthDesc = PasswordService.getPasswordStrengthDescription(
      strength,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(password.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Username', password.username),
            _buildDetailRow('Password', decryptedPassword, isPassword: true),
            if (password.website != null)
              _buildDetailRow('Website', password.website!),
            _buildDetailRow('Category', password.category),
            _buildDetailRow('Strength', '$strengthDesc ($strength/6)'),
            if (password.notes != null)
              _buildDetailRow('Notes', password.notes!),
            _buildDetailRow('Created', _formatDate(password.createdAt)),
            _buildDetailRow('Updated', _formatDate(password.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: decryptedPassword));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password copied to clipboard')),
              );
            },
            tooltip: 'Copy Password',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              isPassword ? '••••••••' : value,
              style: TextStyle(fontFamily: isPassword ? 'monospace' : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Passwords'),
        content: const Text(
          'This will export all your passwords as a JSON file. '
          'Keep this file secure as it contains sensitive information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);

              try {
                final jsonData = await PasswordService.exportPasswords(userId);
                // In a real app, you would save this to a file or share it
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Backup created with ${jsonData.length} characters',
                    ),
                    action: SnackBarAction(
                      label: 'Copy',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonData));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup data copied to clipboard'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating backup: $e')),
                );
              } finally {
                setState(() => isLoading = false);
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password?'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Enter your account email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your email.')),
                );
                return;
              }
              try {
                await AuthService.sendPasswordResetEmail(email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset email sent!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _showBackupDialog,
            tooltip: 'Backup Passwords',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPasswordDialog,
            tooltip: 'Add Password',
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset),
            onPressed: _showForgotPasswordDialog,
            tooltip: 'Forgot Password?',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search passwords',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: selectedCategory == 'All',
                        onSelected: (selected) {
                          setState(() => selectedCategory = 'All');
                        },
                      ),
                      ...PasswordCategories.categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  PasswordCategories.categoryIcons[category] ??
                                      '📁',
                                ),
                                const SizedBox(width: 4),
                                Text(category),
                              ],
                            ),
                            selected: selectedCategory == category,
                            onSelected: (selected) {
                              setState(() => selectedCategory = category);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Passwords List
          Expanded(
            child: StreamBuilder<List<PasswordModel>>(
              stream: searchQuery.isNotEmpty
                  ? PasswordService.searchPasswords(userId, searchQuery)
                  : selectedCategory == 'All'
                  ? PasswordService.getPasswords(userId)
                  : PasswordService.getPasswordsByCategory(
                      userId,
                      selectedCategory,
                    ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No passwords found.\nTap the + button to add your first password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final passwords = snapshot.data!;

                return ListView.builder(
                  itemCount: passwords.length,
                  itemBuilder: (context, index) {
                    final password = passwords[index];
                    final decryptedPassword = PasswordService.decryptPassword(
                      password.encryptedPassword,
                    );
                    final strength = PasswordService.getPasswordStrength(
                      decryptedPassword,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            PasswordCategories.categoryIcons[password
                                    .category] ??
                                '📁',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        title: Text(
                          password.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(password.username),
                            Row(
                              children: [
                                Text(password.category),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStrengthColor(strength),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$strength/6',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (password.isFavorite)
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 16,
                              ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: decryptedPassword),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password copied to clipboard',
                                    ),
                                  ),
                                );
                              },
                              tooltip: 'Copy Password',
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showPasswordDetails(password),
                              tooltip: 'View Details',
                            ),
                          ],
                        ),
                        onTap: () => _showPasswordDetails(password),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPasswordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      case 6:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
