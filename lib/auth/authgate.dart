import 'package:flutter/material.dart';
import 'package:objectiq/auth/login_page.dart';
import 'package:objectiq/screen/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // Listening for auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // Build the appropriate screen based on auth state
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong!")),
          );
        }

        // Get the current session
        final session = Supabase.instance.client.auth.currentSession;

        // Navigate based on session existence
        return session != null ? const HomePage() : const LoginScreen();
      },
    );
  }
}
