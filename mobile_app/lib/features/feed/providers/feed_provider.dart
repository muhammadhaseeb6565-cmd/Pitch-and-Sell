import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import '../../../services/api_service.dart';

class FeedProvider extends ChangeNotifier {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  List<dynamic> get products => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  // Video Controller Memory Pool
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;

  Future<void> fetchFeed(String? initialCategory, String? initialSearch) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (initialCategory != null) _selectedCategory = initialCategory;
      
      final response = await ApiService.getFeed(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: initialSearch,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _products = data['products'] ?? [];
      } else {
        _products = [];
      }
      
      // Initialize the first two videos immediately
      if (_products.isNotEmpty) {
        await _initializeController(0);
        if (_products.length > 1) {
          _initializeController(1);
        }
      }
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    
    // Clear pool before changing feed
    _disposeAllControllers();
    await fetchFeed(null, null);
  }

  VideoPlayerController? getController(int index) {
    return _controllers[index];
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    
    // Play current, pause others
    _controllers.forEach((idx, controller) {
      if (idx == index) {
        controller.play();
      } else {
        controller.pause();
      }
    });

    // Initialize upcoming videos (n+1, n+2)
    _initializeController(index + 1);
    _initializeController(index + 2);
    
    // Initialize previous video (n-1) in case of scrolling up
    _initializeController(index - 1);

    // Force dispose videos that are out of bounds (Memory Management)
    // We only keep index-1, index, index+1, index+2 in memory (max 4 players)
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      if (key < index - 1 || key > index + 2) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
    
    notifyListeners();
  }

  Future<void> _initializeController(int index) async {
    if (index < 0 || index >= _products.length) return;
    if (_controllers.containsKey(index)) return; // Already initialized

    final video = _products[index]['video'];
    if (video == null || video['url'] == null) return;
    
    final url = video['url'];
    VideoPlayerController controller;

    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      if (fileInfo != null) {
        controller = VideoPlayerController.file(fileInfo.file);
      } else {
        // Asynchronous caching (don't block UI)
        DefaultCacheManager().downloadFile(url);
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      }
      
      _controllers[index] = controller;
      await controller.initialize();
      controller.setLooping(true);
      
      // Auto-play if it's the current video that just finished loading
      if (index == _currentIndex) {
        controller.play();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize video at index $index: $e');
    }
  }

  void _disposeAllControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeAllControllers();
    super.dispose();
  }
}
