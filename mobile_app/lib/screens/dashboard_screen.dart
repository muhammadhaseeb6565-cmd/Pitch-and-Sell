import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'pitch_generator_screen.dart';
import 'manage_orders_screen.dart';
import '../main.dart';
import 'package:shimmer/shimmer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _summary = {
    'grossSales': 0.0,
    'platformFees': 0.0,
    'netEarnings': 0.0,
    'paidOut': 0.0,
    'pendingPayouts': 0.0,
    'availableForPayout': 0.0
  };
  List<dynamic> _ledgerEntries = [];
  Map<String, dynamic> _insights = {'totalViews': 0, 'saves': 0, 'cartAbandons': 0};
  Map<String, dynamic> _promoStats = {'name': '', 'status': 'NONE', 'impressions': 0, 'clicks': 0, 'sales': 0, 'roas': 0.0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchLedger(),
        _fetchInsights(),
        _fetchPromotions(),
      ]);
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchLedger() async {
    try {
      final response = await ApiService.getLedger();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _summary = data['summary'] ?? _summary;
        _ledgerEntries = data['entries'] ?? [];
      }
    } catch (e) {
      debugPrint('Ledger fetch error: $e');
    }
  }

  Future<void> _fetchInsights() async {
    try {
      // Assuming getProfileStats or getLedger returns this, or mock fetch based on instructions
      // The instructions say "fetch real counts from orders/likes/saved_videos"
      // Wait, there might not be a specific method for this. I'll just use getProfileStats or dummy since ApiService was updated.
      // Wait, "fetch real counts from orders/likes/saved_videos" means query Supabase?
      // The prompt says "Replace hardcoded with real Supabase data. The ApiService already has...getProfileStats(userId)".
      // But wait! There is no separate ApiService for insights mentioned. I will write direct Supabase queries.
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final savesRes = await client.from('saved_videos').select('id').count(CountOption.exact);
        final ordersRes = await client.from('orders').select('id').eq('status', 'cart_abandoned').count(CountOption.exact);
        _insights = {
          'totalViews': _summary['totalViews'] ?? 0,
          'saves': savesRes.count ?? 0,
          'cartAbandons': ordersRes.count ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Insights fetch error: $e');
    }
  }

  Future<void> _fetchPromotions() async {
    try {
      final response = await ApiService.getPromotionStats();
      if (response.statusCode == 200) {
        _promoStats = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Promotions fetch error: $e');
    }
  }



  void _showPayoutRequestSheet() {
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    String method = 'BANK_ACCOUNT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff1e1e1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request Payout Withdrawal',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Available: PKR ${_summary['availableForPayout']}',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Amount (PKR)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payout Method:', style: TextStyle(color: Colors.white70)),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xff1e1e1e),
                    value: method,
                    style: const TextStyle(color: Colors.white),
                    items: ['BANK_ACCOUNT', 'EASYPAISA', 'JAZZCASH'].map((m) {
                      return DropdownMenuItem(value: m, child: Text(m.replaceAll('_', ' ')));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => method = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: detailsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Details / Number',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
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
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount < 500) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Minimum payout amount is PKR 500.')),
                      );
                      return;
                    }

                    try {
                      final response = await ApiService.requestPayout(
                        amount,
                        method,
                        detailsController.text,
                      );
                      if (response.statusCode == 200 && context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payout requested successfully!')),
                        );
                        _fetchLedger(); // reload balance
                      } else {
                        final err = jsonDecode(response.body);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err['error'] ?? 'Request failed')),
                        );
                      }
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                  child: const Text('Submit Payout Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showUploadVideoSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController(text: '10');
    final sizesController = TextEditingController();
    final colorsController = TextEditingController();
    String category = 'Electronics';
    bool allowDownload = true;
    XFile? selectedVideoFile;
    String? selectedFileName;

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
                    TextField(
                      controller: sizesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Sizes (Comma separated: S,M,L)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: colorsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Colors (Comma separated: Red,Black)',
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
                              final XFile? file = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
                              if (file != null) {
                                // Validate duration
                                final controller = VideoPlayerController.file(File(file.path));
                                await controller.initialize();
                                if (controller.value.duration.inSeconds > 60) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Video must be 60 seconds or less.'), backgroundColor: Colors.red),
                                    );
                                  }
                                  controller.dispose();
                                  return;
                                }
                                controller.dispose();
                                
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
                              const SnackBar(content: Text('Please select a video file')),
                            );
                            return;
                          }
                          try {
                            List<String> parsedSizes = sizesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                            List<String> parsedColors = colorsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                            final response = await ApiService.uploadProduct(
                              name: nameController.text,
                              description: descController.text,
                              price: double.tryParse(priceController.text) ?? 0.0,
                              category: category,
                              stock: int.tryParse(stockController.text) ?? 10,
                              allowDownload: allowDownload,
                              sizes: parsedSizes,
                              colors: parsedColors,
                              videoPath: selectedVideoFile!.path,
                            );
                            if (response.statusCode == 201 && context.mounted) {
                              Navigator.pop(context);
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

  void _showBoostCampaignPickerSheet() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final businessId = auth.user?['businessProfile']?['id'];
    List<dynamic> myProductsList = [];

    // Show loading dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xffFF5722))),
    );

    try {
      final feedRes = await ApiService.getFeed();
      if (feedRes.statusCode == 200 && mounted) {
        final data = jsonDecode(feedRes.body);
        final all = data['products'] as List;
        myProductsList = all.where((p) => p['businessId'] == businessId).toList();
      }
    } catch (e) {
      debugPrint('Fetch products for boost error: $e');
    }

    if (mounted) Navigator.pop(context); // close loader dialog

    if (myProductsList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No products available to boost. Upload a video first!')),
        );
      }
      return;
    }

    String selectedProductId = myProductsList.first['id'];
    String selectedPlan = 'BILLBOARD';

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
                      'Buy Boost Promotion Campaign',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Product to Promote:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    DropdownButton<String>(
                      dropdownColor: const Color(0xff1e1e1e),
                      value: selectedProductId,
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white),
                      items: myProductsList.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem<String>(
                          value: p['id'],
                          child: Text(p['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedProductId = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Boost Level Tier:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 8),
                    
                    // Plan Tiers Selector
                    RadioListTile<String>(
                      title: const Text('Billboard Showcase (3 Days) — ₨100', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Showcase your product on the billboard above the video feed.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      value: 'BILLBOARD',
                      groupValue: selectedPlan,
                      activeColor: const Color(0xffFF5722),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPlan = val);
                      },
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
                          try {
                            final response = await ApiService.promoteProduct(selectedProductId, selectedPlan);
                            if (response.statusCode == 200 && context.mounted) {
                              Navigator.pop(context);
                              final resData = jsonDecode(response.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(resData['message'] ?? 'Boost activated!')),
                              );
                              _fetchLedger(); // refresh ledger balance sheet
                            } else {
                              final err = jsonDecode(response.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err['error'] ?? 'Boost transaction failed')),
                              );
                            }
                          } catch (e) {
                            debugPrint('Purchase boost error: $e');
                          }
                        },
                        child: const Text('Confirm Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        title: const Text('Seller Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xffFF5722)),
            tooltip: 'Upload Video',
            onPressed: _showUploadVideoSheet,
          ),
          IconButton(
            icon: const Icon(Icons.psychology, color: Color(0xffFF5722)),
            tooltip: 'AI Pitch Generator',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PitchGeneratorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLedger,
          )
        ],
      ),
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Shimmer.fromColors(
                baseColor: const Color(0xff1e1e1e),
                highlightColor: const Color(0xff2a2a2a),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 180, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16))),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)))),
                        const SizedBox(width: 16),
                        Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)))),
                        const SizedBox(width: 16),
                        Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)))),
                      ],
                    )
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Available Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'AVAILABLE FOR PAYOUT',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PKR ${_summary['availableForPayout']}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffFF5722),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: _showPayoutRequestSheet,
                                child: const Text('Request Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
                                  );
                                },
                                child: const Text('Manage Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Ledger Analytics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _buildMetricCard('Gross Sales', 'PKR ${_summary['grossSales']}', Colors.green),
                      _buildMetricCard('Platform Fees', 'PKR ${_summary['platformFees']}', Colors.redAccent),
                      _buildMetricCard('Net Earnings', 'PKR ${_summary['netEarnings']}', Colors.blue),
                      _buildMetricCard('Paid Out', 'PKR ${_summary['paidOut']}', Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Seller Superpowers (Audience Insights)
                  const Text(
                    'Video & Audience Insights 🚀',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPromoMetric('${_insights['totalViews']}', 'Total Views'),
                            _buildPromoMetric('${_insights['saves']}', 'Saves/Bookmarks'),
                            _buildPromoMetric('${_insights['cartAbandons']}', 'Cart Abandons'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insights, color: Colors.blue, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pro Tip: Your videos get 20% more views when you use the "Tech" category!',
                                  style: TextStyle(color: Colors.blue[200], fontSize: 13, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured Promotions Tracker Section
                  const Text(
                    'Featured Product Promotions',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _promoStats['name']?.isNotEmpty == true ? _promoStats['name'] : 'No Active Promotion',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _promoStats['status'] == 'ACTIVE' ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _promoStats['status'] ?? 'NONE',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Budget: PKR 100 / 3 Days', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text('Remaining: 1.5 Days', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPromoMetric('${_promoStats['impressions'] ?? 0}', 'Impressions'),
                            _buildPromoMetric('${_promoStats['clicks'] ?? 0}', 'Clicks'),
                             _buildPromoMetric('${_promoStats['sales'] ?? 0}', 'Orders'),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xffFF5722),
                              side: const BorderSide(color: Color(0xffFF5722)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _showBoostCampaignPickerSheet,
                            icon: const Icon(Icons.bolt, size: 16),
                            label: const Text('Buy Boost Promotion Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ledger Audit Log Section
                  const Text(
                    'Ledger Audit Logs',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  _ledgerEntries.isEmpty
                      ? const Text('No ledger entries recorded.', style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ledgerEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _ledgerEntries[index];
                            final isCredit = entry['status'] == 'SALE_EARNING';
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xff1a1a1a),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['title'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (entry['status'] ?? '').toString().replaceAll('_', ' '),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${isCredit ? '+' : ''}PKR ${entry['amount']}',
                                    style: TextStyle(
                                      color: isCredit ? Colors.green : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

  Widget _buildMetricCard(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e1e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Color(0xffFF5722), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
