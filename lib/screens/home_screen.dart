// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'friends_screen.dart';
import 'profile_screen.dart';
import 'completed_tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _token;
  String? _userId;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _tasks = [];
  List<dynamic> _friends = [];
  bool _isLoading = false;

  // Кэшированные списки для оптимизации
  List<dynamic> _activeTasks = [];
  List<dynamic> _completedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _updateCachedLists() {
    _activeTasks = _tasks.where((t) => t['completed'] != true).toList();
    _completedTasks = _tasks.where((t) => t['completed'] == true).toList();
  }

  Future<void> _loadUserData() async {
    if (_isLoading) return;
    _isLoading = true;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');

    if (_token != null && _userId != null) {
      try {
        // Параллельная загрузка данных для ускорения
        final results = await Future.wait([
          ApiService.getProfile(_token!, _userId!),
          ApiService.getTasks(_token!),
          ApiService.getFriends(_token!),
        ]);

        if (mounted) {
          setState(() {
            _userProfile = results[0] as Map<String, dynamic>;
            _tasks = results[1] as List<dynamic>;
            _friends = results[2] as List<dynamic>;
            _updateCachedLists();
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
    _isLoading = false;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            token: _token,
            tasks: _activeTasks,
            userProfile: _userProfile,
            onRefresh: _loadUserData,
          ),
          CompletedTasksScreen(
            token: _token,
            completedTasks: _completedTasks,
            userProfile: _userProfile,
            onRefresh: _loadUserData,
          ),
          FriendsScreen(
            token: _token,
            friends: _friends,
            onRefresh: _loadUserData,
          ),
          ProfileScreen(
            token: _token,
            profile: _userProfile,
            onLogout: _logout,
            onRefresh: _loadUserData,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Тапсырмалар', 0),
                _buildNavItem(Icons.check_circle_rounded, 'Тарих', 1),
                _buildNavItem(Icons.people_rounded, 'Достар', 2),
                _buildNavItem(Icons.person_rounded, 'Профиль', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF6C5CE7).withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? const Color(0xFF6C5CE7)
                      : Colors.white.withOpacity(0.5),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF6C5CE7)
                        : Colors.white.withOpacity(0.5),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
