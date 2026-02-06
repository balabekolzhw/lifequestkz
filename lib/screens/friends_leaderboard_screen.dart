// lib/screens/friends_leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class FriendsLeaderboardScreen extends StatefulWidget {
  final String? token;

  const FriendsLeaderboardScreen({
    super.key,
    required this.token,
  });

  @override
  State<FriendsLeaderboardScreen> createState() =>
      _FriendsLeaderboardScreenState();
}

class _FriendsLeaderboardScreenState extends State<FriendsLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  String _currentSort = 'xp';

  final List<Map<String, dynamic>> _sortOptions = [
    {'key': 'xp', 'label': 'XP', 'icon': Icons.stars_rounded},
    {'key': 'streak', 'label': 'Серия', 'icon': Icons.local_fire_department},
    {'key': 'tasks', 'label': 'Тапсырма', 'icon': Icons.check_circle},
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (widget.token == null) return;

    setState(() => _isLoading = true);
    final data = await ApiService.getFriendsLeaderboard(widget.token!);

    List<dynamic> sortedData = List.from(data);
    _sortData(sortedData);

    setState(() {
      _leaderboard = sortedData;
      _isLoading = false;
    });
  }

  void _sortData(List<dynamic> data) {
    if (_currentSort == 'streak') {
      data.sort((a, b) => (b['streak'] ?? 0).compareTo(a['streak'] ?? 0));
    } else if (_currentSort == 'tasks') {
      data.sort((a, b) => (b['completedTasks'] ?? 0).compareTo(a['completedTasks'] ?? 0));
    } else {
      data.sort((a, b) => (b['xp'] ?? 0).compareTo(a['xp'] ?? 0));
    }
  }

  void _changeSortType(String type) {
    if (_currentSort != type) {
      setState(() {
        _currentSort = type;
        _sortData(_leaderboard);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1F3A),
              Color(0xFF2D1B69),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSortSelector(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _leaderboard.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Рейтинг',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Достарыңмен жарыс',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSortSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: _sortOptions.map((option) {
          final isSelected = _currentSort == option['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeSortType(option['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      option['icon'],
                      size: 18,
                      color: isSelected ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Достар қосыңыз',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Олармен жарысу үшін',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (_leaderboard.length >= 3) _buildPodium(),
          const SizedBox(height: 24),
          _buildLeadersList(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final first = _leaderboard.length > 0 ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          Expanded(
            child: second != null
                ? _buildPodiumPlace(second, 2, 100)
                : const SizedBox(),
          ),
          const SizedBox(width: 8),
          // First place
          Expanded(
            child: first != null
                ? _buildPodiumPlace(first, 1, 130)
                : const SizedBox(),
          ),
          const SizedBox(width: 8),
          // Third place
          Expanded(
            child: third != null
                ? _buildPodiumPlace(third, 3, 80)
                : const SizedBox(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3);
  }

  Widget _buildPodiumPlace(Map<String, dynamic> user, int position, double height) {
    final colors = {
      1: [const Color(0xFFFFD700), const Color(0xFFFFA500)], // Gold
      2: [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)], // Silver
      3: [const Color(0xFFCD7F32), const Color(0xFFB8860B)], // Bronze
    };

    final crownColors = colors[position]!;
    final statValue = _getStatValue(user);
    final statLabel = _getStatLabel();

    return Column(
      children: [
        // Crown for first place
        if (position == 1)
          Icon(
            Icons.workspace_premium,
            color: crownColors[0],
            size: 32,
          ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0, 0)),

        const SizedBox(height: 8),

        // Avatar
        Container(
          width: position == 1 ? 80 : 65,
          height: position == 1 ? 80 : 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: crownColors),
            boxShadow: [
              BoxShadow(
                color: crownColors[0].withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1F3A),
            ),
            child: Center(
              child: Text(
                user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: position == 1 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Username
        Text(
          user['username'] ?? 'User',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: position == 1 ? 16 : 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Stat value
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: crownColors[0].withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$statValue $statLabel',
            style: TextStyle(
              color: crownColors[0],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Podium stand
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                crownColors[0].withOpacity(0.3),
                crownColors[1].withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: crownColors[0].withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$position',
              style: TextStyle(
                color: crownColors[0],
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadersList() {
    // Skip first 3 if we have podium
    final startIndex = _leaderboard.length >= 3 ? 3 : 0;
    final listUsers = _leaderboard.skip(startIndex).toList();

    if (listUsers.isEmpty && _leaderboard.length < 3) {
      // Show all users in list if less than 3
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Қатысушылар',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ..._leaderboard.asMap().entries.map((entry) {
            return _buildListItem(entry.value, entry.key + 1);
          }),
        ],
      );
    }

    if (listUsers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Қалған қатысушылар',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...listUsers.asMap().entries.map((entry) {
          return _buildListItem(entry.value, entry.key + 4);
        }),
      ],
    );
  }

  Widget _buildListItem(Map<String, dynamic> user, int position) {
    final statValue = _getStatValue(user);
    final statColor = _getStatColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
            ),
            child: Center(
              child: Text(
                user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Деңгей ${user['level'] ?? 1}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Stat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCurrentSortIcon(), size: 16, color: statColor),
                const SizedBox(width: 6),
                Text(
                  '$statValue',
                  style: TextStyle(
                    color: statColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * (position - 3)).ms).fadeIn().slideX(begin: 0.1);
  }

  int _getStatValue(Map<String, dynamic> user) {
    switch (_currentSort) {
      case 'streak':
        return user['streak'] ?? 0;
      case 'tasks':
        return user['completedTasks'] ?? 0;
      default:
        return user['xp'] ?? 0;
    }
  }

  String _getStatLabel() {
    switch (_currentSort) {
      case 'streak':
        return 'күн';
      case 'tasks':
        return 'тап.';
      default:
        return 'XP';
    }
  }

  Color _getStatColor() {
    switch (_currentSort) {
      case 'streak':
        return const Color(0xFFFD79A8);
      case 'tasks':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  IconData _getCurrentSortIcon() {
    switch (_currentSort) {
      case 'streak':
        return Icons.local_fire_department;
      case 'tasks':
        return Icons.check_circle;
      default:
        return Icons.stars_rounded;
    }
  }
}
