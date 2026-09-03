import 'package:flutter/material.dart';
import 'feed_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  bool _isLoading = true;

  List<dynamic> _categories = [];
  List<dynamic> _trendingSellers = [];

  @override
  void initState() {
    super.initState();
    _fetchExploreData();
  }

  Future<void> _fetchExploreData() async {
    try {
      final res = await ApiService.getExploreData();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _categories = data['categories'] ?? [];
          _trendingSellers = data['trending_sellers'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Explore Data Fetch Error: $e');
      setState(() => _isLoading = false);
    }
  }

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
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                : GridView.builder(
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
                final name = cat['category'] ?? cat['name'] ?? 'Category';
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text(name), backgroundColor: const Color(0xff1e1e1e)),
                          body: FeedScreen(initialCategory: name),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xffFF5722), Color(0xffFF8A50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: 8,
                        bottom: 8,
                        child: Opacity(
                          opacity: 0.3,
                          child: Icon(Icons.category, size: 48, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cat['count'] ?? 0} Pitches →',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xffFF5722)))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trendingSellers.length,
              itemBuilder: (context, idx) {
                final seller = _trendingSellers[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text('Pitches from ${seller['business_name'] ?? 'Seller'}'), backgroundColor: const Color(0xff1e1e1e)),
                          body: FeedScreen(), // Need to pass business id if feed supports it, for now just feed
                        ),
                      ),
                    );
                  },
                  child: Container(
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
                          child: Text((seller['business_name'] ?? 'S')[0], style: const TextStyle(color: Color(0xffFF5722))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller['business_name'] ?? 'Unknown Business',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${seller['total_orders'] ?? 0} Orders',
                                style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                      ],
                    ),
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
