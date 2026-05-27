import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A widget that synchronizes two videos and allows sliding between them.
/// Perfect for Before/After AI enhancement comparisons.
class VideoComparisonSlider extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;

  const VideoComparisonSlider({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  @override
  State<VideoComparisonSlider> createState() => _VideoComparisonSliderState();
}

class _VideoComparisonSliderState extends State<VideoComparisonSlider> {
  late VideoPlayerController _beforeController;
  late VideoPlayerController _afterController;
  double _sliderValue = 0.5;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    _beforeController = VideoPlayerController.networkUrl(Uri.parse(widget.beforeUrl));
    _afterController = VideoPlayerController.networkUrl(Uri.parse(widget.afterUrl));

    await Future.wait([
      _beforeController.initialize(),
      _afterController.initialize(),
    ]);

    // Sync play/pause
    _beforeController.addListener(() {
      if (_beforeController.value.isPlaying != _afterController.value.isPlaying) {
        if (_beforeController.value.isPlaying) {
          _afterController.play();
        } else {
          _afterController.pause();
        }
      }
      
      // Keep positions in sync (rough sync for MVP)
      final diff = (_beforeController.value.position.inMilliseconds - 
                    _afterController.value.position.inMilliseconds).abs();
      if (diff > 100) {
        _afterController.seekTo(_beforeController.value.position);
      }
    });

    setState(() {
      _isInitialized = true;
    });
    
    _beforeController.setLooping(true);
    _afterController.setLooping(true);
    _beforeController.play();
  }

  @override
  void dispose() {
    _beforeController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _sliderValue += details.delta.dx / constraints.maxWidth;
              _sliderValue = _sliderValue.clamp(0.0, 1.0);
            });
          },
          child: AspectRatio(
            aspectRatio: _beforeController.value.aspectRatio,
            child: Stack(
              children: [
                // After (Enhanced) - Background
                VideoPlayer(_afterController),
                
                // Before (Original) - Clipped
                ClipRect(
                  clipper: _VideoSliderClipper(_sliderValue),
                  child: VideoPlayer(_beforeController),
                ),
                
                // Labels
                _buildLabel("BEFORE", Alignment.topLeft),
                _buildLabel("ENHANCED", Alignment.topRight, isAccent: true),

                // Handle
                Positioned(
                  left: constraints.maxWidth * _sliderValue - 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: const Color(0xFF22D3EE),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22D3EE).withOpacity(0.5),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: const Icon(Icons.unfold_more_rounded, 
                          color: Color(0xFF22D3EE), 
                          size: 24
                        ),
                      ),
                    ),
                  ),
                ),

                // Playback controls overlay
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconButton(
                      iconSize: 64,
                      icon: Icon(
                        _beforeController.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: () {
                        setState(() {
                          _beforeController.value.isPlaying 
                            ? _beforeController.pause() 
                            : _beforeController.play();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, Alignment alignment, {bool isAccent = false}) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAccent ? const Color(0xFF22D3EE).withOpacity(0.8) : Colors.black54,
            borderRadius: BorderRadius.circular(20),
            backdropFilter: const ColorFilter.mode(Colors.black12, BlendMode.blur),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isAccent ? Colors.black : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoSliderClipper extends CustomClipper<Rect> {
  final double position;
  _VideoSliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_VideoSliderClipper oldClipper) => oldClipper.position != position;
}