import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Your Movies module
import 'screens/movies_list_screen.dart';

// Auth screens from feature-auth
import 'features/auth/vew/screens/login_screen.dart';
import 'features/auth/vew/screens/sign_up_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Movies App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // Choose the initial screen:
      // Option 1: Start with auth (LoginScreen)
      // home: LoginScreen(),

      // Option 2: Start directly with your Movies list for testing
      home: const MoviesListScreen(currentUserId: "testUserId"),

      debugShowCheckedModeBanner: false,
    );
  }
}