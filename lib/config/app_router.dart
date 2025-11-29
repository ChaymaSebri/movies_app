import 'package:flutter/material.dart';
import 'package:movies_app/constants/app_routes.dart';

import 'package:movies_app/screens/auth/login_screen.dart';
import 'package:movies_app/screens/auth/sign_up_screen.dart';
import 'package:movies_app/screens/auth/profile_screen.dart';
// import 'package:movies_app/screens/auth/edit_profile_screen.dart';

import 'package:movies_app/screens/movies/movies_list_screen.dart';
import 'package:movies_app/screens/movies/movie_detail_screen.dart';
import 'package:movies_app/screens/movies/favorites_screen.dart';
import 'package:movies_app/screens/admin_dashboard.dart';
import 'package:movies_app/services/auth_service.dart';
import 'package:movies_app/services/admin_service.dart';
import 'package:movies_app/screens/matching_page.dart';
import 'package:movies_app/screens/match_detail_page.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signUp: (context) => const SignUpScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),

      // AppRoutes.editProfile: (context) => const EditProfileScreen(),
      AppRoutes.moviesList: (context) => const MoviesListScreen(),
      AppRoutes.movieDetail: (context) => const MovieDetailScreen(),
      AppRoutes.favorites: (context) => const FavoritesScreen(),
      AppRoutes.adminDashboard: (context) => FutureBuilder<bool>(
        future: () async {
          final user = AuthService().currentUser;
          if (user == null) return false;
          return await AdminService().isAdmin(user.uid);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isAdmin = snapshot.data == true;
          if (!isAdmin) {
            return Scaffold(
              appBar: AppBar(title: const Text('Accès refusé')),
              body: const Center(child: Text("Vous n\'êtes pas autorisé.")),
            );
          }
          return const AdminDashboard();
        },
      ),
      AppRoutes.matching: (context) => const MatchingPage(),
      AppRoutes.matchDetail: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MatchDetailPage(data: args);
      },
    };
  }
}
