import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// English Comment: User Dashboard displaying user information and stats.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _examHistory = [];
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final historyRes = await _supabase
          .from('exam_attempts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _userProfile = profileRes;
        _examHistory = List<Map<String, dynamic>>.from(historyRes as List);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IT-Ace Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabase.auth.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: const Color(0xFFF3EEFC),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF6B4EE6),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        _userProfile?['full_name'] ?? user?.email ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user?.email ?? ''),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Exam Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _examHistory.isEmpty
                        ? const Center(child: Text('No exam records found.'))
                        : ListView.builder(
                            itemCount: _examHistory.length,
                            itemBuilder: (context, index) {
                              final attempt = _examHistory[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title: Text(attempt['subject_name'] ?? 'Subject Exam'),
                                  subtitle: Text(
                                    'Correct: ${attempt['correct_answers']} / ${attempt['total_questions']}',
                                  ),
                                  trailing: Text(
                                    'Score: ${attempt['score']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B4EE6),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}