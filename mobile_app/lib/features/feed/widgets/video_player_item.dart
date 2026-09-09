import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/api_service.dart';
import '../../../screens/seller_profile_screen.dart';
import '../services/feed_dialog_service.dart';
import '../services/video_export_service.dart';

class VideoPlayerItem extends StatefulWidget {
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
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  VideoPlayerController? _controller;
  double _horizontalDrag = 0.0;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likesCount = 0;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    final video = widget.productData['video'];
    if (video != null && video['url'] != null) {
      _initVideoPlayer(video['url']);
      _likesCount = video['likesCount'] ?? 0;
    }
    _isLiked = widget.productData['isLiked'] ?? false;
    if (widget.productData['isSaved'] != null) {
      _isSaved = widget.productData['isSaved'] == true;
    } else {
      _checkInitialSavedState();
    }
  }

  Future<void> _checkInitialSavedState() async {
    final pid = widget.productData['id']?.toString();
    if (pid != null && pid.isNotEmpty) {
      final saved = await ApiService.isVideoSaved(pid);
      if (mounted) setState(() => _isSaved = saved);
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(url);
      if (fileInfo != null) {
        _controller = VideoPlayerController.file(fileInfo.file);
      } else {
        final file = await DefaultCacheManager().getSingleFile(url);
        _controller = VideoPlayerController.file(file);
      }
      
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        if (widget.isVisible && widget.isFocused) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }
    } catch (e) {
      debugPrint('Video caching error: $e. Falling back to network stream.');
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
        if (widget.isVisible && widget.isFocused) {
          _controller?.play();
        }
        _controller?.setLooping(true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
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

    if (widget.productData['isSaved'] != null && widget.productData['isSaved'] != _isSaved) {
      _isSaved = widget.productData['isSaved'] == true;
    }
    if (widget.productData['isLiked'] != null && widget.productData['isLiked'] != _isLiked) {
      _isLiked = widget.productData['isLiked'] == true;
    }
  }


  void _handleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to like videos.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      if (_likesCount < 0) _likesCount = 0;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
    try {
      final pid = widget.productData['id']?.toString() ?? widget.productData['video']?['id']?.toString() ?? '';
      if (pid.isNotEmpty) {
        await ApiService.likeVideo(pid);
      }
    } catch (e) {
      debugPrint('Like action error: $e');
    }
  }

  void _handleSaveVideo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Please sign in to save videos for later.'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final previousState = _isSaved;
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      final productId = widget.productData['id']?.toString() ?? '';
      final res = await ApiService.toggleSaveVideo(productId);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bool isNowSaved = data['saved'] == true;
        if (mounted) {
          setState(() {
            _isSaved = isNowSaved;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    isNowSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(isNowSaved ? 'Video saved for later! 📌' : 'Removed from saved videos.'),
                ],
              ),
              backgroundColor: isNowSaved ? const Color(0xffFF5722) : Colors.grey[800],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSaved = previousState;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update saved status. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        setState(() {
          _isSaved = previousState;
        });
      }
    }
  }

  void _handleDeleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e1e1e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Pitch Video?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.productData['name']}"? This will permanently remove it from your store and the feed.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Deleting pitch video...'),
            ],
          ),
          duration: Duration(seconds: 15),
        ),
      );

      try {
        final res = await ApiService.deleteProduct(widget.productData['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Pitch video deleted successfully! 🗑️'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          String errMsg = 'Failed to delete video';
          try {
            final data = jsonDecode(res.body);
            if (data['error'] != null) errMsg = data['error'];
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errMsg)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _handleShareProduct() async {
    final videoUrl = widget.productData['video']?['url'];
    if (videoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video not available.')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Adding watermark & preparing video...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/pitchandsell_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final watermarkText = 'PitchAndSell - @${widget.productData['business']?['name'] ?? 'Seller'}';
      
      // FFmpeg command to add text watermark at bottom center
      final command = "-y -i '${file.path}' -vf \"drawtext=text='$watermarkText':fontcolor=white@0.9:fontsize=32:x=(w-tw)/2:y=h-th-60:shadowcolor=black@0.6:shadowx=2:shadowy=2\" -c:a copy '$outPath'";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (ReturnCode.isSuccess(returnCode)) {
        final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
        await Share.shareXFiles(
          [XFile(outPath)], 
          text: 'Watch this awesome product by @${widget.productData['business']?['name'] ?? 'Seller'} on PitchAndSell!\n\nBuy it here: $link',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add watermark. Sharing link only...')));
        final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
        Share.share('Check out this product on PitchAndSell: $link');
      }
    } catch (e) {
      debugPrint('Watermark error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final link = 'https://pitch-and-sell-backend.onrender.com/product/${widget.productData['id']}';
      Share.share('Check out this product on PitchAndSell: $link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Player Background
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_controller != null) {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            }
          },
          onDoubleTap: _handleLike,
          onHorizontalDragStart: (details) => _horizontalDrag = 0.0,
          onHorizontalDragUpdate: (details) {
            _horizontalDrag += details.delta.dx;
          },
          onHorizontalDragEnd: (details) {
            if (_horizontalDrag < -40 || (details.primaryVelocity != null && details.primaryVelocity! < -300)) {
              final sellerId = widget.productData['seller_id'] ?? '';
              if (sellerId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellerProfileScreen(
                      sellerId: sellerId,
                      businessName: widget.productData['business']?['name'] ?? 'Seller',
                    ),
                  ),
                );
              }
            }
          },
          child: Container(
            color: Colors.black,
            child: _controller != null && _controller!.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller?.value.size.width ?? 0,
                        height: _controller?.value.size.height ?? 0,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Color(0xffFF5722))),
          ),
        ),

        // Pause Indicator
        if (_controller != null && _controller!.value.isInitialized && !_controller!.value.isPlaying)
          IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),

        // Floating Double Tap Heart Animation
        if (_showHeart)
          const Center(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 400),
              child: Icon(
                Icons.favorite,
                color: Color(0xffFF5722),
                size: 80,
              ),
            ),
          ),

        // Overlay Shadow (IgnorePointer so touches pass through to video player GestureDetector)
        IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent, Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Bottom Product Description
        Positioned(
          left: 16,
          bottom: 32,
          right: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final sellerId = widget.productData['seller_id'] ?? '';
                        if (sellerId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(
                                sellerId: sellerId,
                                businessName: widget.productData['business']?['name'] ?? 'Seller',
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        '@${widget.productData['business']?['name'] ?? 'Seller'}',
                        style: const TextStyle(color: Color(0xffFF5722), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.productData['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.productData['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    if (widget.productData['avgRating'] != null && widget.productData['avgRating'] > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${(widget.productData['avgRating'] as num).toStringAsFixed(1)} (${widget.productData['reviewCount']})',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'PKR ${widget.productData['price']}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (widget.productData['oldPrice'] != null)
                          Text(
                            'PKR ${widget.productData['oldPrice']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Action Column
        Positioned(
          right: 12,
          bottom: 32,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like
              GestureDetector(
                onTap: _handleLike,
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? const Color(0xffFF5722) : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 2),
                    Text('$_likesCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Review
              GestureDetector(
                onTap: () => FeedDialogService.showCommentsSheet(context, widget.productData),
                child: const Column(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 28),
                    SizedBox(height: 2),
                    Text('Review', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Save for Later
              GestureDetector(
                onTap: _handleSaveVideo,
                child: Column(
                  children: [
                    Icon(
                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isSaved ? const Color(0xffFF5722) : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isSaved ? 'Saved' : 'Save',
                      style: TextStyle(
                        color: _isSaved ? const Color(0xffFF5722) : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Share Product Link
              GestureDetector(
                onTap: _handleShareProduct,
                child: const Column(
                  children: [
                    Icon(Icons.share_rounded, color: Colors.white, size: 26),
                    SizedBox(height: 2),
                    Text('Share', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (widget.productData['allowDownload'] == true ||
                  widget.productData['allow_download'] == true) ...[
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => VideoExportService.downloadVideo(
                      context, widget.productData),
                  child: const Column(
                    children: [
                      Icon(Icons.download_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(height: 2),
                      Text('Save',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              if (Supabase.instance.client.auth.currentUser?.id != null &&
                  Supabase.instance.client.auth.currentUser?.id == widget.productData['seller_id']) ...[
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _handleDeleteProduct,
                  child: const Column(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                      SizedBox(height: 2),
                      Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // Order Now Action Button (Cart)
              GestureDetector(
                onTap: () => FeedDialogService.showOrderCheckoutSheet(context, widget.productData),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF5722),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}







