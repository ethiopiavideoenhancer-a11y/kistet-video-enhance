import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

enum ComparisonMode { slider, split, toggle }

class ComparisonMaster extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;

  const ComparisonMaster({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  @override
  State<ComparisonMaster> createState() => _ComparisonMasterState();
}

class _ComparisonMasterState extends State<ComparisonMaster> with TickerProviderStateMixin {
  late VideoPlayerController _beforeController;
  late VideoPlayerController _afterController;
  ComparisonMode _currentMode = ComparisonMode.slider;
  double _sliderValue = 0.5;
  bool _isInitialized = false;
  bool _isEnhancedVisible = true; // For Toggle mode
  
  late AnimationController _modeFadeController;

  @override
  void initState() {
    super.initState();
    _modeFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _initVideos();
  }

  Future<void> _initVideos() async {
    _beforeController = VideoPlayerController.networkUrl(Uri.parse(widget.beforeUrl));
    _afterController = VideoPlayerController.networkUrl(Uri.parse(widget.afterUrl));

    await Future.wait([
      _beforeController.initialize(),
      _afterController.initialize(),
    ]);

    // Precise Sync Listener
    _beforeController.addListener(_syncPlayback);
    
    _beforeController.setLooping(true);
    _afterController.setLooping(true);
    _beforeController.play();
    _afterController.play();

    setState(() => _isInitialized = true);
  }

  void _syncPlayback() {
    if (!mounted) return;
    
    // Sync Play/Pause state
    if (_beforeController.value.isPlaying != _afterController.value.isPlaying) {
      if (_beforeController.value.isPlaying) {
        _afterController.play();
      } else {
        _afterController.pause();
      }
    }

    // Temporal Sync (Keep within 100ms)
    final diff = (_beforeController.value.position.inMilliseconds - 
                  _afterController.value.position.inMilliseconds).abs();
    if (diff > 100) {
      _afterController.seekTo(_beforeController.value.position);
    }
  }

  @override
  void dispose() {
    _beforeController.removeListener(_syncPlayback);
    _beforeController.dispose();
    _afterController.dispose();
    _modeFadeController.dispose();
    super.dispose();
  }

  void _switchMode(ComparisonMode mode) {
    if (_currentMode == mode) return;
    _modeFadeController.reverse().then((_) {
      setState(() {
        _currentMode = mode;
        _modeFadeController.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22D3EE),
          strokeWidth: 2,
        ),
      );
    }

    return Column(
      children: [
        // Premium Mode Selector
        _buildPremiumModeSelector(),
        
        // Dynamic Player Canvas
        Expanded(
          child: FadeTransition(
            opacity: _modeFadeController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withOpacity(0.05),
                      blurRadius: 40,
                      spreadRadius: 2,
                    )
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildComparisonCanvas(),
              ),
            ),
          ),
        ),

        // Intelligent Controls
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPremiumModeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeOption(ComparisonMode.slider, "SLIDER", Icons.unfold_more_rounded),
          _modeOption(ComparisonMode.split, "SPLIT", Icons.splitscreen_rounded),
          _modeOption(ComparisonMode.toggle, "TOGGLE", Icons.swap_horiz_rounded),
        ],
      ),
    );
  }

  Widget _modeOption(ComparisonMode mode, String label, IconData icon) {
    bool isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22D3EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.black : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCanvas() {
    switch (_currentMode) {
      case ComparisonMode.slider:
        return _buildSliderCanvas();
      case ComparisonMode.split:
        return _buildSplitCanvas();
      case ComparisonMode.toggle:
        return _buildToggleCanvas();
    }
  }

  Widget _buildSliderCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _sliderValue += details.delta.dx / constraints.maxWidth;
              _sliderValue = _sliderValue.clamp(0.0, 1.0);
            });
          },
          child: Stack(
            children: [
              SizedBox.expand(child: VideoPlayer(_afterController)),
              ClipRect(
                clipper: _CanvasClipper(_sliderValue),
                child: SizedBox.expand(child: VideoPlayer(_beforeController)),
              ),
              // Interaction Handle
              Positioned(
                left: constraints.maxWidth * _sliderValue - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.5), blurRadius: 10)
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                      ),
                      child: const Icon(Icons.unfold_more_rounded, color: Color(0xFF22D3EE), size: 24),
                    ),
                  ),
                ),
              ),
              _buildCanvasLabel("BEFORE", Alignment.topLeft),
              _buildCanvasLabel("ENHANCED", Alignment.topRight, isAccent: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitCanvas() {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _beforeController.value.size.width / 2,
                    height: _beforeController.value.size.height,
                    child: VideoPlayer(_beforeController),
                  ),
                ),
              ),
            ),
            Container(width: 2, color: const Color(0xFF22D3EE)),
            Expanded(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _afterController.value.size.width / 2,
                    height: _afterController.value.size.height,
                    child: VideoPlayer(_afterController),
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildCanvasLabel("ORIGINAL", Alignment.bottomLeft),
        _buildCanvasLabel("ENHANCED", Alignment.bottomRight, isAccent: true),
      ],
    );
  }

  Widget _buildToggleCanvas() {
    return GestureDetector(
      onTap: () => setState(() => _isEnhancedVisible = !_isEnhancedVisible),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: SizedBox.expand(
              key: ValueKey(_isEnhancedVisible),
              child: VideoPlayer(_isEnhancedVisible ? _afterController : _beforeController),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isEnhancedVisible ? const Color(0xFF22D3EE) : Colors.black54,
                borderRadius: BorderRadius.circular(12),
                backdropFilter: const ColorFilter.mode(Colors.black, BlendMode.blur),
              ),
              child: Text(
                _isEnhancedVisible ? "AI ENHANCED" : "ORIGINAL",
                style: TextStyle(
                  color: _isEnhancedVisible ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.touch_app_rounded, color: Colors.white24, size: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasLabel(String text, Alignment align, {bool isAccent = false}) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAccent ? const Color(0xFF22D3EE).withOpacity(0.8) : Colors.black45,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isAccent ? Colors.black : Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _actionIcon(Icons.replay_rounded, () {
            _beforeController.seekTo(Duration.zero);
            _afterController.seekTo(Duration.zero);
          }),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () {
              setState(() {
                _beforeController.value.isPlaying ? _beforeController.pause() : _beforeController.play();
              });
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF22D3EE),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 20)
                ],
              ),
              child: Icon(
                _beforeController.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 44,
              ),
            ),
          ),
          const SizedBox(width: 40),
          _actionIcon(Icons.fullscreen_rounded, () {
            // Fullscreen trigger
          }),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _CanvasClipper extends CustomClipper<Rect> {
  final double pos;
  _CanvasClipper(this.pos);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * pos, size.height);
  @override
  bool shouldReclip(_CanvasClipper old) => old.pos != pos;
}