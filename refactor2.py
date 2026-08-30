import re

with open('mobile_app/lib/screens/feed_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'onPageChanged: \(index\) \{',
    r'onPageChanged: (index) {\n                          setState(() => _currentIndex = index);',
    content
)

content = re.sub(
    r'return VideoPlayerItem\(\n\s*productData: _products\[index\],\n\s*isVisible: widget\.isVisible,',
    r'return VideoPlayerItem(\n                            productData: _products[index],\n                            isVisible: widget.isVisible,\n                            isFocused: index == _currentIndex,',
    content
)

with open('mobile_app/lib/screens/feed_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done fixing itemBuilder")
