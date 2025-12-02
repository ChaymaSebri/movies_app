import 'package:flutter/material.dart';
import 'package:movies_app/constants/app_routes.dart';

import 'package:movies_app/screens/auth/login_screen.dart';
import 'package:movies_app/screens/auth/sign_up_screen.dart';
import 'package:movies_app/screens/auth/profile_screen.dart';
import 'package:movies_app/screens/auth/edit_profile_screen.dart';
import 'package:movies_app/screens/auth/reset_password_screen.dart';

import 'package:movies_app/screens/movies/movies_list_screen.dart';
import 'package:movies_app/screens/movies/movie_detail_screen.dart';
import 'package:movies_app/screens/movies/favorites_screen.dart';

import 'package:movies_app/screens/admin+matching/admin_dashboard_screen.dart';
import 'package:movies_app/screens/admin+matching/matching_screen.dart';
import 'package:movies_app/screens/admin+matching/match_detail_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signUp: (context) => const SignUpScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      AppRoutes.editProfile: (context) => const EditProfileScreen(),
      AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),

      AppRoutes.moviesList: (context) => const MoviesListScreen(),
      AppRoutes.movieDetail: (context) => const MovieDetailScreen(),
      AppRoutes.favorites: (context) => const FavoritesScreen(),

      AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),

      AppRoutes.matching: (context) => const MatchingPage(),
      AppRoutes.matchDetail: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return MatchDetailScreen(data: args);
      },
    };
  }
}
