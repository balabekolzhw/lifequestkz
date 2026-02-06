// lib/screens/completed_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class CompletedTasksScreen extends StatefulWidget {
  final String? token;
  final List<dynamic> completedTasks;
  final Map<String, dynamic>? userProfile;
  final VoidCallback onRefresh;

  const CompletedTasksScreen({
    Key? key,
    required this.token,
    required this.completedTasks,
    required this.userProfile,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  String _selectedFilter = 'all';
  String _selectedTimeRange = 'all';
  late List<dynamic> _localTasks;

  @override
  void initState() {
    super.initState();
    _localTasks = List.from(widget.completedTasks);
  }

  @override
  void didUpdateWidget(CompletedTasksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedTasks != oldWidget.completedTasks) {
      _localTasks = List.from(widget.completedTasks);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (widget.token == null) return;

    final response = await ApiService.deleteTask(widget.token!, taskId);

    if (response['success'] == true) {
      setState(() {
        _localTasks = _localTasks.where((task) => task['_id'] != taskId).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Тапсырма жойылды'),
            backgroundColor: const Color(0xFF6C5CE7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      widget.onRefresh();
    }
  }

  List<dynamic> get _filteredTasks {
    var tasks = List.from(_localTasks);

    // Filter by category
    if (_selectedFilter != 'all') {
      tasks = tasks.where((t) => t['category'] == _selectedFilter).toList();
    }

    // Filter by time range
    final now = DateTime.now();
    if (_selectedTimeRange == 'today') {
      tasks = tasks.where((t) {
        final completedAt = DateTime.tryParse(t['completedAt'] ?? '');
        if (completedAt == null) return false;
        return completedAt.day == now.day &&
            completedAt.month == now.month &&
            completedAt.year == now.year;
      }).toList();
    } else if (_selectedTimeRange == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      tasks = tasks.where((t) {
        final completedAt = DateTime.tryParse(t['completedAt'] ?? '');
        if (completedAt == null) return false;
        return completedAt.isAfter(weekAgo);
      }).toList();
    } else if (_selectedTimeRange == 'month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      tasks = tasks.where((t) {
        final completedAt = DateTime.tryParse(t['completedAt'] ?? '');
        if (completedAt == null) return false;
        return completedAt.isAfter(monthAgo);
      }).toList();
    }

    // Sort by completion date (newest first)
    tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a['completedAt'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['completedAt'] ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return tasks;
  }

  int get _totalXPEarned {
    return _filteredTasks.fold(0, (sum, task) => sum + (task['xp'] as int? ?? 0));
  }

  Map<String, int> get _categoryStats {
    final stats = <String, int>{
      'study': 0,
      'health': 0,
      'finance': 0,
      'general': 0,
    };
    for (var task in _filteredTasks) {
      final category = task['category'] ?? 'general';
      stats[category] = (stats[category] ?? 0) + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00B894).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Жетістіктер',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Орындалған тапсырмалар тарихы',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.2),

                    const SizedBox(height: 24),

                    // Stats Cards
                    _buildStatsRow(),

                    const SizedBox(height: 24),

                    // Filters
                    _buildFilters(),
                  ],
                ),
              ),
            ),

            // Category breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCategoryBreakdown(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tasks header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Орындалған тапсырмалар',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filteredTasks.length}',
                        style: const TextStyle(
                          color: Color(0xFF00B894),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Tasks list
            _filteredTasks.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildEmptyState(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final card = _buildTaskCard(_filteredTasks[index], index);
                          // Анимация только для первых 5 элементов
                          if (index < 5) {
                            return card.animate(delay: (50 * index).ms).fadeIn(duration: 200.ms);
                          }
                          return card;
                        },
                        childCount: _filteredTasks.length,
                      ),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            icon: Icons.check_circle,
            value: '${_filteredTasks.length}',
            label: 'Орындалды',
            colors: [const Color(0xFF00B894), const Color(0xFF55EFC4)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMiniStatCard(
            icon: Icons.stars,
            value: '$_totalXPEarned',
            label: 'XP жиналды',
            colors: [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String value,
    required String label,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.15)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors[0].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors[0],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time range filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'Барлық уақыт', _selectedTimeRange == 'all', (v) {
                setState(() => _selectedTimeRange = 'all');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('today', 'Бүгін', _selectedTimeRange == 'today', (v) {
                setState(() => _selectedTimeRange = 'today');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('week', 'Апта', _selectedTimeRange == 'week', (v) {
                setState(() => _selectedTimeRange = 'week');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('month', 'Ай', _selectedTimeRange == 'month', (v) {
                setState(() => _selectedTimeRange = 'month');
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Category filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', 'Барлығы', Icons.apps),
              const SizedBox(width: 8),
              _buildCategoryChip('study', 'Оқу', Icons.school),
              const SizedBox(width: 8),
              _buildCategoryChip('health', 'Денсаулық', Icons.favorite),
              const SizedBox(width: 8),
              _buildCategoryChip('finance', 'Қаржы', Icons.monetization_on),
              const SizedBox(width: 8),
              _buildCategoryChip('general', 'Жалпы', Icons.task_alt),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildFilterChip(String value, String label, bool isSelected, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final isSelected = _selectedFilter == category;
    final categoryColors = {
      'all': [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
      'study': [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      'health': [const Color(0xFF00B894), const Color(0xFF55EFC4)],
      'finance': [const Color(0xFFFF6B6B), const Color(0xFFFDCB6E)],
      'general': [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
    };

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: categoryColors[category]!)
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final stats = _categoryStats;
    final total = _filteredTasks.length;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Санаттар бойынша бөлу',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar('Оқу', stats['study']!, total, const Color(0xFF6C5CE7)),
          const SizedBox(height: 10),
          _buildProgressBar('Денсаулық', stats['health']!, total, const Color(0xFF00B894)),
          const SizedBox(height: 10),
          _buildProgressBar('Қаржы', stats['finance']!, total, const Color(0xFFFF6B6B)),
          const SizedBox(height: 10),
          _buildProgressBar('Жалпы', stats['general']!, total, const Color(0xFF74B9FF)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: (MediaQuery.of(context).size.width - 180) * percentage,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Орындалған тапсырмалар жоқ',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Тапсырмаларды орындаңыз, олар осында көрінеді',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final category = task['category'] ?? 'general';
    final categoryColors = {
      'study': [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
      'health': [const Color(0xFF00B894), const Color(0xFF55EFC4)],
      'finance': [const Color(0xFFFF6B6B), const Color(0xFFFDCB6E)],
      'general': [const Color(0xFF74B9FF), const Color(0xFF0984E3)],
    };

    final completedAt = DateTime.tryParse(task['completedAt'] ?? '');
    final dateStr = completedAt != null
        ? '${completedAt.day.toString().padLeft(2, '0')}.${completedAt.month.toString().padLeft(2, '0')}.${completedAt.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: categoryColors[category]!),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: categoryColors[category]![0].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(_getCategoryIcon(category), color: Colors.white, size: 24),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B894),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Тапсырма',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // XP earned and delete button
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withOpacity(0.2),
                        const Color(0xFFA29BFE).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Color(0xFFA29BFE), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '+${task['xp'] ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFFA29BFE),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _deleteTask(task['_id']),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFFF6B6B),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'study':
        return Icons.school;
      case 'health':
        return Icons.favorite;
      case 'finance':
        return Icons.monetization_on;
      default:
        return Icons.task_alt;
    }
  }
}
