import 'package:flutter/material.dart';
import 'package:objectiq/auth/login_page.dart';
import 'package:objectiq/screen/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    // Simulate some startup delay (e.g. loading assets, checking auth)
    await Future.delayed(const Duration(seconds: 2));

    final user = Supabase.instance.client.auth.currentUser;
    // Replace the splash with either HomePage or LoginScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => user != null ? HomePage() : LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Your logo or app name
            FlutterLogo(size: 100),
            const SizedBox(height: 24),
            const Text(
              'ObjectIQ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
