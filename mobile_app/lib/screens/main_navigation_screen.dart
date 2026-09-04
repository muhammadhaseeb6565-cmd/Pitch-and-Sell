import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'feed_screen.dart';
import 'messages_list_screen.dart';
import 'orders_history_screen.dart';
import 'profile_screen.dart';
import 'package:image_picker/image_picker.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  bool _isSeller(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.hasBusinessProfile;
  }

  void _onItemTapped(int index) {
    final isSeller = _isSeller(context);
    if (isSeller && index == 2) {
      // Seller mode: middle tab is Upload
      _triggerUploadFlow();
      return;
    }
    setState(() {
      if (isSeller) {
        // Seller: 5 tabs → Home(0), Chat(1), Upload(skip), Orders(2), Profile(3)
        _selectedIndex = index > 2 ? index - 1 : index;
      } else {
        // Customer: 4 tabs → Home(0), Chat(1), Orders(2), Profile(3)
        _selectedIndex = index;
      }
    });
  }

  void _triggerUploadFlow() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.hasBusinessProfile) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xff1e1e1e),
          title: const Text('Business Profile Required', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Please onboard or register a Business Profile in the Profile tab to upload pitch videos.', style: TextStyle(color: Colors.grey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xffFF5722))),
            ),
          ],
        ),
      );
      return;
    }

    _showUploadVideoSheet();
  }

  void _showUploadVideoSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController(text: '10');
    final videoUrlController = TextEditingController(
      text: 'https://assets.mixkit.co/videos/preview/mixkit-hands-typing-on-a-mechanical-keyboard-41724-large.mp4',
    );
    String category = 'Electronics';
    bool allowDownload = true;
    String? selectedFileName;
    XFile? selectedVideoFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload New Pitch Video',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Price (PKR)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Category:', style: TextStyle(color: Colors.white70)),
                        DropdownButton<String>(
                          dropdownColor: const Color(0xff1e1e1e),
                          value: category,
                          style: const TextStyle(color: Colors.white),
                          items: ['Electronics', 'Fashion', 'Home', 'Services'].map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => category = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Stock Qty',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Video Selector Row
                    const Text('Select Pitch Video:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e1e1e),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              selectedFileName ?? 'No video selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFF5722).withOpacity(0.12),
                              foregroundColor: const Color(0xffFF5722),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
                              if (file != null) {
                                setModalState(() {
                                  selectedVideoFile = file;
                                  selectedFileName = file.name;
                                });
                              }
                            },
                            icon: const Icon(Icons.video_library, size: 16),
                            label: const Text('Choose Video', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Allow Viewers to Download:', style: TextStyle(color: Colors.white70)),
                        Switch(
                          value: allowDownload,
                          activeColor: const Color(0xffFF5722),
                          onChanged: (val) {
                            setModalState(() => allowDownload = val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFF5722),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameController.text.isEmpty || priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill name and price')),
                            );
                            return;
                          }
                          if (selectedVideoFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a video file from gallery or drive')),
                            );
                            return;
                          }

                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return const Center(
                                child: CircularProgressIndicator(color: Color(0xffFF5722)),
                              );
                            },
                          );

                          try {
                            final response = await ApiService.uploadProduct(
                              name: nameController.text,
                              description: descController.text,
                              price: double.tryParse(priceController.text) ?? 0.0,
                              category: category,
                              stock: int.tryParse(stockController.text) ?? 10,
                              allowDownload: allowDownload,
                              videoPath: selectedVideoFile!.path,
                            );
                            Navigator.pop(context); // pop progress dialog
                            if (response.statusCode == 200 && context.mounted) {
                              Navigator.pop(context); // close sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product and video uploaded successfully.')),
                              );
                            } else {
                              final err = jsonDecode(response.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err['error'] ?? 'Upload failed')),
                              );
                            }
                          } catch (e) {
                            debugPrint('Upload error: $e');
                          }
                        },
                        child: const Text('Publish Pitch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = _isSeller(context);

    // Pages for IndexedStack
    final pages = <Widget>[
      FeedScreen(isVisible: _selectedIndex == 0),   // 0: Home
      const MessagesListScreen(),                     // 1: Chat
      const OrdersHistoryScreen(),                    // 2: Orders
      const ProfileScreen(),                          // 3: Profile
    ];

    // Bottom nav items for Customer (4 tabs)
    final customerNavItems = const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    // Bottom nav items for Seller (5 tabs — Upload in the middle)
    final sellerNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
      BottomNavigationBarItem(
        icon: Container(
          width: 44,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xffFF5722),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
        label: '',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    // Calculate the nav bar index from the page index
    int navIndex;
    if (isSeller) {
      navIndex = _selectedIndex >= 2 ? _selectedIndex + 1 : _selectedIndex;
    } else {
      navIndex = _selectedIndex;
    }

    // Clamp to valid range
    final maxIndex = isSeller ? sellerNavItems.length - 1 : customerNavItems.length - 1;
    if (navIndex > maxIndex) navIndex = maxIndex;
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff1e1e1e),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xffFF5722),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        currentIndex: navIndex,
        onTap: _onItemTapped,
        items: isSeller ? sellerNavItems : customerNavItems,
      ),
    );
  }
}

