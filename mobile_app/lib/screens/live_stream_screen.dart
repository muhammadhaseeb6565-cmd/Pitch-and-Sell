import 'dart:async';
import 'package:flutter/material.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final List<String> _comments = [
    'Wow, the quality looks amazing!',
    'Is cash on delivery available in Karachi?',
    'What is the price of the headphones?',
    'Just placed an order! Release escrow when delivered.',
    'Can you show the black variant once?',
    'Super fast responses!',
  ];
  final List<String> _liveFeed = [];
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _viewerCount = 142;
  Timer? _timer;
  int _heartCount = 0;

  @override
  void initState() {
    super.initState();
    _liveFeed.add('Welcome to Emulgic Live Commerce Stream!');
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _viewerCount += (timer.tick % 2 == 0) ? 3 : -2;
          final nextComment = _comments[timer.tick % _comments.length];
          _liveFeed.add('Buyer_${100 + timer.tick}: $nextComment');
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Video Placeholder Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff121212), Color(0xff1f1f1f)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(Icons.videocam, color: Colors.white24, size: 80),
            ),
          ),

          // Header Overlay
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_viewerCount',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Streamer Badge Info
          Positioned(
            top: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xffFF5722),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tahir Pitafi',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(color: Color(0xffFF5722), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comments area & Input & Floating hearts
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pinned Product Card
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xffFF5722).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag, color: Color(0xffFF5722), size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Super Bass Headphones V2',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₨ 4,500',
                                style: TextStyle(color: Color(0xffFF5722), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffFF5722),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () {},
                          child: const Text('Buy', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Real-time Chat Stream Area
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _liveFeed.length,
                      itemBuilder: (context, idx) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _liveFeed[idx],
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom message input & Floating Heart Action
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Say something nice...',
                            hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white12,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _liveFeed.add('You: ${val.trim()}');
                              });
                              _commentController.clear();
                              _scrollToBottom();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Floating heart button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _heartCount++;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xffFF5722),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.favorite, color: Colors.white),
                              if (_heartCount > 0)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_heartCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
