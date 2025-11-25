import 'package:flutter/material.dart';
import 'package:movies_app/constants/app_routes.dart';

import 'package:movies_app/screens/auth/login_screen.dart';
import 'package:movies_app/screens/auth/sign_up_screen.dart';
import 'package:movies_app/screens/auth/profile_screen.dart';
// import 'package:movies_app/screens/auth/edit_profile_screen.dart';

import 'package:movies_app/screens/movies/movies_list_screen.dart';
import 'package:movies_app/screens/movies/movie_detail_screen.dart';
import 'package:movies_app/screens/movies/favorites_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signUp: (context) => const SignUpScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      // AppRoutes.editProfile: (context) => const EditProfileScreen(),

      // AppRoutes.moviesList: (context) => const MoviesListScreen(),
      // AppRoutes.movieDetail: (context) => const MovieDetailScreen(),
      // AppRoutes.favorites: (context) => const FavoritesScreen(),
    };
  }
}
