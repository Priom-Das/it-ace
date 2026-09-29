import 'package:flutter/material.dart';
import '../subjects/subject_list_screen.dart';
import 'user_dashboard_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart'; // AI Assistant Screen import 

// English Comment: Main Navigation Bar separating Home Content, AI Assistant, and User Dashboard.
class MainTabNavigation extends StatefulWidget {
  const MainTabNavigation({super.key});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    SubjectListScreen(),
    AiAssistantScreen(), // AI Assistant Screen 
    UserDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}