import 'package:flutter/material.dart';
import 'feed_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Fashion & Style', 'icon': '👔', 'color1': 0xffFF5722, 'color2': 0xffFF8A50},
    {'name': 'Tech & AI', 'icon': '💻', 'color1': 0xff3F51B5, 'color2': 0xff7986CB},
    {'name': 'Food & Organic', 'icon': '🥗', 'color1': 0xff4CAF50, 'color2': 0xff81C784},
    {'name': 'Coaching', 'icon': '🎓', 'color1': 0xff9C27B0, 'color2': 0xffBA68C8},
    {'name': 'Handmade', 'icon': '🎨', 'color1': 0xffFF9800, 'color2': 0xffFFB74D},
    {'name': 'Services', 'icon': '🛠️', 'color1': 0xff00BCD4, 'color2': 0xff4DD0E1},
    {'name': 'Health', 'icon': '❤️', 'color1': 0xffE91E63, 'color2': 0xffF06292},
    {'name': 'Finance', 'icon': '📈', 'color1': 0xff607D8B, 'color2': 0xff90A4AE},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Explore Pitches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search pitches, products, sellers...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xff1e1e1e),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('Search: $val'), backgroundColor: const Color(0xff1e1e1e)),
                        body: FeedScreen(initialSearch: val),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Horizontal Filter Bar
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Trending', 'New Pitches', 'Top Sellers'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xffFF5722) : const Color(0xff1e1e1e),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Browse Categories',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Grid categories
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(cat['name']), backgroundColor: const Color(0xff1e1e1e)),
                          body: FeedScreen(initialCategory: cat['name']),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(cat['color1']), Color(cat['color2'])],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Opacity(
                          opacity: 0.3,
                          child: Text(
                            cat['icon'],
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Discover →',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ));
              },
            ),
            const SizedBox(height: 32),

            const Text(
              'Trending Businesses',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, idx) {
                final names = ['Haseeb Electronics', 'Tahir Leather Co', 'Organic Farms PK'];
                final tags = ['Verified Seller', 'KYC ✓', 'Top 1%'];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e1e1e),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffFF5722).withOpacity(0.1),
                        child: Text(names[idx][0], style: const TextStyle(color: Color(0xffFF5722))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              names[idx],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tags[idx],
                              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
