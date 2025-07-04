// features/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../home/home_screen.dart';
import '../../services/log_service.dart';
import '../welcome/post_registration_welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsLogin;
  const LoginScreen({super.key, this.initialIsLogin = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _profileImageController = TextEditingController();
  String _role = 'parent';
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  Future<void> _submit() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      LogService.d('[UI] _submit called. _isLogin=$_isLogin');
      if (_isLogin) {
        LogService.d(
          '[UI] Attempting sign in for ${_emailController.text.trim()}',
        );
        final cred = await AuthService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        LogService.d('[UI] Sign in successful. UID: ${cred.user?.uid}');
        // Fetch user profile
        LogService.d(
          '[UI] About to fetch user profile for ${cred.user!.uid} after login',
        );
        final user = await AuthService.getUserProfile(cred.user!.uid);
        LogService.d('[UI] getUserProfile returned: $user');
        if (mounted && user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeScreenWithRole(user: user)),
          );
        } else {
          LogService.d('[UI] User profile is null after login.');
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Login Error'),
                content: const Text('User profile could not be loaded.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Registration validation
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final profileImage = _profileImageController.text.trim();
        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          setState(() {
            _error = 'All fields are required.';
            _loading = false;
          });
          return;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4} ').hasMatch(email)) {
          setState(() {
            _error = 'Please enter a valid email address.';
            _loading = false;
          });
          return;
        }
        if (password.length < 6) {
          setState(() {
            _error = 'Password must be at least 6 characters.';
            _loading = false;
          });
          return;
        }
        LogService.d('[UI] Attempting sign up for $email');
        final cred = await AuthService.createUserWithEmailAndPassword(
          email,
          password,
        );
        LogService.d('[UI] Sign up successful. UID: ${cred.user?.uid}');
        // Create user profile
        await AuthService.createUserProfile(
          uid: cred.user!.uid,
          name: name,
          email: email,
          role: _role,
          profileImageUrl: profileImage.isNotEmpty ? profileImage : null,
        );
        LogService.d('[UI] User profile created for sign up.');
        // Fetch user profile
        LogService.d(
          '[UI] About to fetch user profile for ${cred.user!.uid} after sign up',
        );
        final user = await AuthService.getUserProfile(cred.user!.uid);
        LogService.d('[UI] getUserProfile returned: $user');
        if (mounted && user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PostRegistrationWelcomeScreen(user: user),
            ),
          );
        } else {
          LogService.d('[UI] User profile is null after sign up.');
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Up Error'),
                content: const Text('User profile could not be loaded.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e, stack) {
      LogService.e('[UI] Exception in _submit', e);
      LogService.e('[UI] Exception stack', stack);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    LogService.d('[DEBUG] LoginScreen build called');
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isLogin) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _profileImageController,
                decoration: const InputDecoration(
                  labelText: 'Profile Image URL (optional)',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Role:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _role,
                    items: const [
                      DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      DropdownMenuItem(value: 'child', child: Text('Child')),
                      DropdownMenuItem(value: 'nanny', child: Text('Nanny')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'parent'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(
                _isLogin
                    ? 'Create an account'
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreenWithRole extends StatelessWidget {
  final UserModel user;
  const HomeScreenWithRole({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return HomeScreen(user: user);
  }
}
