import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_player/better_player.dart';

class CompareVideoScreen extends StatefulWidget {
  final String originalUrl;
  final String enhancedUrl;

  const CompareVideoScreen({
    super.key,
    required this.originalUrl,
    required this.enhancedUrl,
  });

  @override
  State<CompareVideoScreen> createState() => _CompareVideoScreenState();
}

class _CompareVideoScreenState extends State<CompareVideoScreen> with TickerProviderStateMixin {
  late VideoPlayerController _originalController;
  late VideoPlayerController _enhancedController;
  late TabController _tabController;
  
  bool _isInitialized = false;
  bool _isSyncing = false;
  double _sliderPosition = 0.5;
  bool _showSliderMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initPlayers();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _syncPlayback();
      }
    });
  }

  Future<void> _initPlayers() async {
    _originalController = VideoPlayerController.networkUrl(Uri.parse(widget.originalUrl));
    _enhancedController = VideoPlayerController.networkUrl(Uri.parse(widget.enhancedUrl));

    await Future.wait([
      _originalController.initialize(),
      _enhancedController.initialize(),
    ]);

    // Loop and play both
    _originalController.setLooping(true);
    _enhancedController.setLooping(true);
    
    _originalController.play();
    _enhancedController.play();

    // Attach listeners for sync
    _originalController.addListener(_onPositionChanged);

    setState(() {
      _isInitialized = true;
    });
  }

  void _onPositionChanged() {
    if (_isSyncing) return;
    
    // Periodically force sync if they drift
    final diff = (_originalController.value.position.inMilliseconds - 
                  _enhancedController.value.position.inMilliseconds).abs();
    if (diff > 150) {
      _isSyncing = true;
      _enhancedController.seekTo(_originalController.value.position).then((_) {
        _isSyncing = false;
      });
    }
  }

  void _syncPlayback() {
    // When switching tabs, ensure the other player matches position
    if (_tabController.index == 0) {
      // Switched to Original
      _originalController.seekTo(_enhancedController.value.position);
    } else {
      // Switched to Enhanced
      _enhancedController.seekTo(_originalController.value.position);
    }
  }

  @override
  void dispose() {
    _originalController.removeListener(_onPositionChanged);
    _originalController.dispose();
    _enhancedController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'COMPARISON',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSliderMode ? Icons.view_agenda : Icons.compare,
              color: const Color(0xFF22D3EE),
            ),
            onPressed: () => setState(() => _showSliderMode = !_showSliderMode),
          ),
        ],
        bottom: !_showSliderMode ? TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF22D3EE),
          labelColor: const Color(0xFF22D3EE),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ORIGINAL'),
            Tab(text: 'ENHANCED'),
          ],
        ) : null,
      ),
      body: Stack(
        children: [
          _showSliderMode ? _buildSliderView() : _buildTabView(),
          
          // Controls Overlay
          _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return TabBarView(
      controller: _tabController,
      physics: const NeverScrollableScrollPhysics(), // Managed by tabs
      children: [
        Center(child: AspectRatio(aspectRatio: _originalController.value.aspectRatio, child: VideoPlayer(_originalController))),
        Center(child: AspectRatio(aspectRatio: _enhancedController.value.aspectRatio, child: VideoPlayer(_enhancedController))),
      ],
    );
  }

  Widget _buildSliderView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _sliderPosition += details.delta.dx / constraints.maxWidth;
              _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              // After (Enhanced) - Background
              Center(child: AspectRatio(aspectRatio: _enhancedController.value.aspectRatio, child: VideoPlayer(_enhancedController))),
              
              // Before (Original) - Clipped
              Center(
                child: AspectRatio(
                  aspectRatio: _originalController.value.aspectRatio,
                  child: ClipRect(
                    clipper: _SliderClipper(_sliderPosition),
                    child: VideoPlayer(_originalController),
                  ),
                ),
              ),

              // Handle
              Positioned(
                left: constraints.maxWidth * _sliderPosition - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: const Color(0xFF22D3EE),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                      ),
                      child: const Icon(Icons.unfold_more_rounded, color: Color(0xFF22D3EE), size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Seek bar (Simplified)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: VideoProgressIndicator(
              _originalController, 
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF22D3EE),
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                onPressed: () {
                  final newPos = _originalController.value.position - const Duration(seconds: 10);
                  _originalController.seekTo(newPos);
                  _enhancedController.seekTo(newPos);
                },
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_originalController.value.isPlaying) {
                      _originalController.pause();
                      _enhancedController.pause();
                    } else {
                      _originalController.play();
                      _enhancedController.play();
                    }
                  });
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22D3EE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _originalController.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                onPressed: () {
                  final newPos = _originalController.value.position + const Duration(seconds: 10);
                  _originalController.seekTo(newPos);
                  _enhancedController.seekTo(newPos);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double position;
  _SliderClipper(this.position);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * position, size.height);
  @override
  bool shouldReclip(_SliderClipper oldClipper) => oldClipper.position != position;
}