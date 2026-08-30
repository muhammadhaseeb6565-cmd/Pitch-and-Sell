import re

with open('mobile_app/lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _currentIndex to _FeedScreenState
content = re.sub(
    r'(bool _isLoading = true;\n\s*PageController\? _pageController;\n\s*String _selectedCategory = \'All\';)',
    r'\1\n  int _currentIndex = 0;',
    content
)

# 2. Update PageView.builder onPageChanged to update _currentIndex
onPageChangedReplacement = r'''onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        // Pre-load the next 2 videos into cache for zero buffering
'''
content = content.replace('onPageChanged: (index) {\n                          // Pre-load', onPageChangedReplacement)

# 3. Pass index and currentIndex to VideoPlayerItem in itemBuilder
itemBuilderReplacement = r'''itemBuilder: (context, index) {
                        return VideoPlayerItem(
                          productData: _products[index],
                          isVisible: widget.isVisible && index == _currentIndex,
                          isFocused: index == _currentIndex,
                          onChatPressed: (chatId, title) {'''
content = content.replace('itemBuilder: (context, index) {\n                          return VideoPlayerItem(\n                            productData: _products[index],\n                            isVisible: widget.isVisible,\n                            onChatPressed: (chatId, title) {', itemBuilderReplacement)

# 4. Update VideoPlayerItem constructor to accept isFocused
videoPlayerItemClassReplacement = r'''class VideoPlayerItem extends StatefulWidget {
  final Map<String, dynamic> productData;
  final Function(String chatId, String title) onChatPressed;
  final bool isVisible;
  final bool isFocused;

  const VideoPlayerItem({
    super.key,
    required this.productData,
    required this.onChatPressed,
    this.isVisible = true,
    this.isFocused = false,
  });'''
content = re.sub(
    r'class VideoPlayerItem extends StatefulWidget \{.*?this\.isVisible = true,\n\s*\}\);',
    videoPlayerItemClassReplacement,
    content,
    flags=re.DOTALL
)

# 5. Update _VideoPlayerItemState to handle didUpdateWidget properly for isFocused
didUpdateWidgetReplacement = r'''@override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFocused && !widget.isFocused) {
      _controller?.pause();
      _controller?.seekTo(Duration.zero); // Reset video
    } else if (!oldWidget.isFocused && widget.isFocused && widget.isVisible) {
      _controller?.play();
    }
    
    if (oldWidget.isVisible && !widget.isVisible) {
      _controller?.pause();
    } else if (!oldWidget.isVisible && widget.isVisible && widget.isFocused) {
      _controller?.play();
    }
  }'''
content = re.sub(
    r'@override\n\s*void didUpdateWidget\(covariant VideoPlayerItem oldWidget\) \{.*?(?=\n\s*void _handleLike\(\))',
    didUpdateWidgetReplacement + '\n',
    content,
    flags=re.DOTALL
)

# 6. Ensure _initVideoPlayer only plays if isFocused and isVisible
initVideoReplacement = r'''if (mounted) {
        setState(() {});
        if (widget.isVisible && widget.isFocused) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }'''
content = content.replace('''if (mounted) {
        setState(() {});
        if (widget.isVisible) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }''', initVideoReplacement)

with open('mobile_app/lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done refactoring feed_screen.dart")
