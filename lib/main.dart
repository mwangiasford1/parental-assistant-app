// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/settings_provider.dart';
import 'first_launch_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parental Assistant',
      home: const FirstLaunchWrapper(),
      theme: Provider.of<ThemeProvider>(context).themeData,
      routes: {'/login': (context) => const LoginScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
