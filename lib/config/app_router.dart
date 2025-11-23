import 'package:flutter/material.dart';
import 'package:movies_app/core/constants/app_routes.dart';
import 'package:movies_app/features/auth/views/screens/login_screen.dart';
import 'package:movies_app/features/auth/views/screens/sign_up_screen.dart';
import 'package:movies_app/features/profile/views/screens/profile_screen.dart';
// import 'package:movies_app/features/profile/views/screens/edit_profile_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.signUp: (context) => const SignUpScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      // AppRoutes.editProfile: (context) => const EditProfileScreen(),
      // Ajouter les autres routes ici
    };
  }
}