import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:objectiq/auth/login_page.dart';
import 'package:objectiq/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  //get auth service
  final _supabaseAuth = Supabase.instance.client.auth;

  @override
  Widget build(BuildContext context) {
    //get user email
    final email = getCurrentUserEmail() ?? 'No Email';

    return Scaffold(
      backgroundColor:
          Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
              ? Colors.black
              : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            'Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.indigo.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileSection(email),
          const Divider(),
          _buildThemeSwitch(context),
          const Divider(),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String currentEmail) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.email)),
      title: Text(currentEmail.toString()),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          value: themeProvider.themeMode == ThemeMode.dark,
          onChanged: (value) => themeProvider.toggleTheme(value),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Logout', style: TextStyle(color: Colors.red)),
      onTap: () async {
        await _supabaseAuth.signOut();
        log("logout");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      },
    );
  }
}
