// English Comment: Main entry point for the IT-Ace Flutter application initializing Supabase services and Routing.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // English Comment: Initialize Supabase client with project configuration.
  await Supabase.initialize(
    url: 'https://vnnnhwalzqgwitlrqyxc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZubm5od2FsenFnd2l0bHJxeXhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAyMjQzMjgsImV4cCI6MjEwNTgwMDMyOH0.LU5DJHCwNEWdao7O-RPd9xCjyyyQ7aAkBvscFrk53nY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IT-Ace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4EE6)),
        scaffoldBackgroundColor: const Color(0xFFF7F4FD),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}