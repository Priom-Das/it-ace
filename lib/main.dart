// Main entry point for the IT-Ace Flutter application initializing Supabase services and Routing.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importing dotenv for secure environment variable management.
import 'views/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file for secure API key management.
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Handle missing .env file gracefully without crashing the app.
  }

  // Initialize Supabase client with project configuration.
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