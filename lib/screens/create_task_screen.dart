// lib/screens/create_task_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? token;
  final VoidCallback onTaskCreated;

  const CreateTaskScreen({
    Key? key,
    required this.token,
    required this.onTaskCreated,
  }) : super(key: key);

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'general';
  int _selectedXP = 10;
  String _selectedPriority = 'medium';
  bool _isCreating = false;

  static const List<Map<String, dynamic>> _quickTemplates = [
    {
      'title': 'Кітап оқу',
      'description': '30 минут кітап оқу',
      'category': 'study',
      'xp': 20,
      'priority': 'medium',
      'icon': Icons.menu_book,
    },
    {
      'title': 'Жаттығулар',
      'description': '20 минут спортпен шұғылдану',
      'category': 'health',
      'xp': 30,
      'priority': 'high',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Су ішу',
      'description': '8 стакан су ішу',
      'category': 'health',
      'xp': 10,
      'priority': 'low',
      'icon': Icons.water_drop,
    },
    {
      'title': 'Үй жинау',
      'description': 'Бөлмені тазалау',
      'category': 'general',
      'xp': 25,
      'priority': 'medium',
      'icon': Icons.cleaning_services,
    },
    {
      'title': 'Ақша жинау',
      'description': 'Бүгінгі шығындарды жазу',
      'category': 'finance',
      'xp': 15,
      'priority': 'medium',
      'icon': Icons.savings,
    },
    {
      'title': 'Тіл үйрену',
      'description': '15 минут ағылшын тілін үйрену',
      'category': 'study',
      'xp': 25,
      'priority': 'medium',
      'icon': Icons.language,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _titleController.text = template['title'];
      _descriptionController.text = template['description'];
      _selectedCategory = template['category'];
      _selectedXP = template['xp'];
      _selectedPriority = template['priority'];
    });
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Тапсырма атауын енгізіңіз'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    if (widget.token != null) {
      final response = await ApiService.createTask(
        widget.token!,
        _titleController.text,
        _descriptionController.text,
        _selectedCategory,
        _selectedXP,
        _selectedPriority,
      );

      if (response['success'] == true) {
        widget.onTaskCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Тапсырма құрылды!'),
                ],
              ),
              backgroundColor: const Color(0xFF00B894),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Қате орын алды'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isCreating = false);
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
            colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF2D1B69)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Шапка
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CustomIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                      size: 48,
                      gradientColors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Жаңа тапсырма',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Мақсатқа жету жолында',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              // Форма
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Быстрые шаблоны
                      _buildSectionTitle('Жылдам шаблондар', Icons.flash_on),
                      const SizedBox(height: 12),
                      _buildQuickTemplates().animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 24),

                      // Название
                      _buildSectionTitle('Тапсырма атауы', Icons.title),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'Мысалы: Математикадан үй тапсырмасын орындау',
                        icon: Icons.edit,
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 24),

                      // Описание
                      _buildSectionTitle(
                        'Сипаттама (міндетті емес)',
                        Icons.description,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Қосымша мәліметтер...',
                        icon: Icons.notes,
                        maxLines: 3,
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // Категория
                      _buildSectionTitle('Санат', Icons.category),
                      const SizedBox(height: 12),
                      _buildCategorySelector().animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 24),

                      // Приоритет
                      _buildSectionTitle('Маңыздылық', Icons.flag),
                      const SizedBox(height: 12),
                      _buildPrioritySelector().animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 24),

                      // XP награда
                      _buildSectionTitle('XP сыйақы', Icons.stars),
                      const SizedBox(height: 12),
                      _buildXPSlider().animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 32),

                      // Кнопка создать
                      CustomButton(
                        text: 'Тапсырма құру',
                        icon: Icons.add_task,
                        onPressed: _createTask,
                        gradientColors: const [
                          Color(0xFF6C5CE7),
                          Color(0xFFA29BFE),
                        ],
                        width: double.infinity,
                        height: 56,
                        isLoading: _isCreating,
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTemplates() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _quickTemplates.length,
        itemBuilder: (context, index) {
          final template = _quickTemplates[index];
          final categoryColors = {
            'study': const Color(0xFF6C5CE7),
            'health': const Color(0xFF00B894),
            'finance': const Color(0xFFFF6B6B),
            'general': const Color(0xFF74B9FF),
          };
          final color =
              categoryColors[template['category']] ?? const Color(0xFF74B9FF);

          return GestureDetector(
            onTap: () => _applyTemplate(template),
            child: Container(
              width: 110,
              margin: EdgeInsets.only(
                right: index < _quickTemplates.length - 1 ? 12 : 0,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      template['icon'] as IconData,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {
        'id': 'study',
        'name': 'Оқу',
        'icon': Icons.school,
        'color': const Color(0xFF6C5CE7),
      },
      {
        'id': 'health',
        'name': 'Денсаулық',
        'icon': Icons.favorite,
        'color': const Color(0xFF00B894),
      },
      {
        'id': 'finance',
        'name': 'Қаржы',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFFF6B6B),
      },
      {
        'id': 'general',
        'name': 'Жалпы',
        'icon': Icons.task_alt,
        'color': const Color(0xFF74B9FF),
      },
    ];

    return Row(
      children:
          categories.map((cat) {
            final isSelected = _selectedCategory == cat['id'];
            final color = cat['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap:
                    () =>
                        setState(() => _selectedCategory = cat['id'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                        color: isSelected ? color : Colors.white54,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = [
      {'id': 'low', 'name': 'Төмен', 'color': const Color(0xFF00B894)},
      {'id': 'medium', 'name': 'Орташа', 'color': const Color(0xFFFDCB6E)},
      {'id': 'high', 'name': 'Жоғары', 'color': const Color(0xFFFF6B6B)},
    ];

    return Row(
      children:
          priorities.map((pri) {
            final isSelected = _selectedPriority == pri['id'];
            final color = pri['color'] as Color;
            return Expanded(
              child: GestureDetector(
                onTap:
                    () =>
                        setState(() => _selectedPriority = pri['id'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? color.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pri['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildXPSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.15),
            const Color(0xFFA29BFE).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сыйақы таңдаңыз',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$_selectedXP XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C5CE7),
              inactiveTrackColor: const Color(0xFF6C5CE7).withOpacity(0.2),
              thumbColor: const Color(0xFFA29BFE),
              overlayColor: const Color(0xFF6C5CE7).withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 6,
            ),
            child: Slider(
              value: _selectedXP.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: (value) {
                setState(() => _selectedXP = value.toInt());
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
              Text(
                '100 XP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
