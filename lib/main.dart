// main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// import 'package:objectiq/provider/auth_provider.dart';
import 'package:objectiq/provider/history_provider.dart';
import 'package:objectiq/provider/theme_provider.dart';
import 'package:objectiq/screen/splash_page.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Only get available cameras on non-web platforms.
  if (!kIsWeb) {
    cameras = await availableCameras();
  }
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatelessWidget {
  final bool isDark;
  const MyApp({Key? key, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final currentUser = Supabase.instance.client.auth.currentUser;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(isDark),
        ),
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (__, themeProvider, ___) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
