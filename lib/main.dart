// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/movies_list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/admin/add_movie_screen.dart'; // si tu veux tester l'ajout

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charge le .env (Cloudinary)
  await dotenv.load(fileName: ".env");

  // Initialise Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // UN USER ID FIXE POUR TESTER RAPIDEMENT (change-le si tu veux)
  static const String testUserId = "user_12345";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movies App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      home: const MoviesListScreen(currentUserId: testUserId),

      // === ROUTES BONUS POUR TESTER FACILEMENT ===
      routes: {
        '/favorites': (_) => FavoritesScreen(currentUserId: testUserId),
        '/add-movie': (_) => const AddMovieScreen(),
      },
    );
  }
}

// === PETIT BOUTON FLOTTANT POUR TESTER L'AJOUT RAPIDE (optionnel) ===
class MoviesListScreenWithFab extends StatelessWidget {
  const MoviesListScreenWithFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MoviesListScreen(currentUserId: MyApp.testUserId),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        child: const Icon(Icons.admin_panel_settings),
        onPressed: () {
          // Va directement à l'écran admin
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMovieScreen()));
        },
      ),
    );
  }
}