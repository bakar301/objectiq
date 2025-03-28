// main.dart
import 'package:flutter/material.dart';
import 'package:objectiq/auth/login_page.dart';
import 'package:objectiq/provider/auth_provider.dart';
import 'package:objectiq/provider/history_provider.dart';
import 'package:objectiq/provider/theme_provider.dart';
import 'package:objectiq/screen/home_page.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'globals.dart';

const supabaseUrl = "https://jegrusfxgdlkaxangwvo.supabase.co";
const supabaseAnonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplZ3J1c2Z4Z2Rsa2F4YW5nd3ZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI5MTk0OTYsImV4cCI6MjA1ODQ5NTQ5Nn0.M1GPFvhqmShnjj18HQqhvkJmAdB8FXQCTwbwtXuW61Y";

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()` can be called before `runApp()` is called.

  WidgetsFlutterBinding.ensureInitialized();

//supabase initialization
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Get the list of available cameras.
  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: currentUser != null ? HomePage() : LoginScreen(),
          );
        },
      ),
    );
  }
}
