import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class CategoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final IconData icon;
  final Color accentColor;

  const CategoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.icon,
    required this.accentColor,
  });
}

class CategoryPreferencesScreen extends StatefulWidget {
  final bool isFirstTime;

  const CategoryPreferencesScreen({
    super.key,
    this.isFirstTime = false,
  });

  @override
  State<CategoryPreferencesScreen> createState() => _CategoryPreferencesScreenState();
}

class _CategoryPreferencesScreenState extends State<CategoryPreferencesScreen> {
  final Set<String> _selectedCategories = <String>{};
  bool _isSaving = false;

  static const List<CategoryItem> kCategories = [
    CategoryItem(
      id: 'Clothing',
      title: 'Clothing & Fashion',
      subtitle: 'Eastern, Western, Kurtas & Daily Wear',
      emoji: '👕',
      icon: Icons.checkroom_rounded,
      accentColor: Color(0xffE91E63),
    ),
    CategoryItem(
      id: 'Foods',
      title: 'Foods & Snacks',
      subtitle: 'Sweets, Organic, Snacks & Homemade',
      emoji: '🍔',
      icon: Icons.fastfood_rounded,
      accentColor: Color(0xffFF9800),
    ),
    CategoryItem(
      id: 'Medicine',
      title: 'Health & Medicine',
      subtitle: 'Supplements, Healthcare & Personal Care',
      emoji: '💊',
      icon: Icons.medical_services_rounded,
      accentColor: Color(0xff00BCD4),
    ),
    CategoryItem(
      id: 'Electronics',
      title: 'Electronics & Gadgets',
      subtitle: 'Smartphones, Audio, Cables & Tech',
      emoji: '📱',
      icon: Icons.devices_other_rounded,
      accentColor: Color(0xff2196F3),
    ),
    CategoryItem(
      id: 'Beauty',
      title: 'Beauty & Cosmetics',
      subtitle: 'Skincare, Makeup & Fragrances',
      emoji: '💄',
      icon: Icons.face_retouching_natural_rounded,
      accentColor: Color(0xff9C27B0),
    ),
    CategoryItem(
      id: 'Footwear',
      title: 'Footwear & Shoes',
      subtitle: 'Sneakers, Formal, Sandals & Chappals',
      emoji: '👟',
      icon: Icons.roller_skating_rounded,
      accentColor: Color(0xff4CAF50),
    ),
    CategoryItem(
      id: 'Jewelry',
      title: 'Watches & Jewelry',
      subtitle: 'Chains, Rings, Luxury & Accessories',
      emoji: '⌚',
      icon: Icons.watch_rounded,
      accentColor: Color(0xffFFC107),
    ),
    CategoryItem(
      id: 'Home',
      title: 'Home & Kitchen',
      subtitle: 'Cookware, Decor, Organizers & Living',
      emoji: '🍳',
      icon: Icons.kitchen_rounded,
      accentColor: Color(0xff795548),
    ),
    CategoryItem(
      id: 'Sports',
      title: 'Sports & Fitness',
      subtitle: 'Gym Gear, Cricket Kits & Activewear',
      emoji: '🏋️',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xff009688),
    ),
    CategoryItem(
      id: 'Books',
      title: 'Books & Stationery',
      subtitle: 'Novels, Notebooks, Islamic & Art',
      emoji: '📚',
      icon: Icons.menu_book_rounded,
      accentColor: Color(0xff3F51B5),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.preferredCategories.isNotEmpty) {
      _selectedCategories.addAll(auth.preferredCategories);
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  Future<void> _handleSaveAndContinue({bool isSkipping = false}) async {
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final List<String> toSave = isSkipping
          ? (_selectedCategories.isEmpty ? ['Clothing', 'Electronics', 'Foods'] : _selectedCategories.toList())
          : _selectedCategories.toList();

      await auth.savePreferredCategories(toSave);

      if (!mounted) return;

      if (widget.isFirstTime) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Feed categories updated! Personalized for you.'),
              ],
            ),
            backgroundColor: Color(0xff2e7d32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = Color(0xffFF5722);
    final hasMinimum = _selectedCategories.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xff121212) : const Color(0xffF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xff1A1A1A) : Colors.white,
        elevation: 0,
        leading: widget.isFirstTime
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.isFirstTime ? 'Personalize Feed' : 'Feed Preferences',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.isFirstTime)
            TextButton(
              onPressed: _isSaving ? null : () => _handleSaveAndContinue(isSkipping: true),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              color: isDark ? const Color(0xff1A1A1A) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Color(0xffFF5722), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What are you interested in?',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select categories you want to see most in your video feed.',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress / Selection count indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasMinimum
                              ? primaryColor.withOpacity(0.15)
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasMinimum ? primaryColor : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_selectedCategories.length} selected',
                          style: TextStyle(
                            color: hasMinimum ? primaryColor : (isDark ? Colors.white60 : Colors.black54),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectedCategories.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _selectedCategories.clear()),
                          child: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // Category Selection Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: kCategories.length,
                itemBuilder: (context, index) {
                  final cat = kCategories[index];
                  final isSelected = _selectedCategories.contains(cat.id);

                  return GestureDetector(
                    onTap: () => _toggleCategory(cat.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xff2A1E1A) : const Color(0xffFFF3E0))
                            : (isDark ? const Color(0xff1E1E1E) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Emoji and Checkmark
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: cat.accentColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cat.emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.grey),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                cat.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                cat.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black54,
                                  fontSize: 10.5,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Floating Action Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey,
                    elevation: hasMinimum ? 3 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (!hasMinimum || _isSaving)
                      ? null
                      : () => _handleSaveAndContinue(isSkipping: false),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isFirstTime ? 'Continue to Feed' : 'Save Preferences',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
