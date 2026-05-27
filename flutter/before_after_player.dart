import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

enum ComparisonMode { slider, split, toggle }

class BeforeAfterPlayer extends StatefulWidget {
  final String beforeUrl;
  final String afterUrl;

  const BeforeAfterPlayer({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  @override
  State<BeforeAfterPlayer> createState() => _BeforeAfterPlayerState();
}

class _BeforeAfterPlayerState extends State<BeforeAfterPlayer> with TickerProviderStateMixin {
  late VideoPlayerController _beforeController;
  late VideoPlayerController _afterController;
  ComparisonMode _currentMode = ComparisonMode.slider;
  double _sliderValue = 0.5;
  bool _isInitialized = false;
  bool _isToggledToAfter = true;
  
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _initPlayers();
  }

  Future<void> _initPlayers() async {
    _beforeController = VideoPlayerController.networkUrl(Uri.parse(widget.beforeUrl));
    _afterController = VideoPlayerController.networkUrl(Uri.parse(widget.afterUrl));

    await Future.wait([
      _beforeController.initialize(),
      _afterController.initialize(),
    ]);

    // Frame-lock Sync Listener
    _beforeController.addListener(_synchronize);
    
    _beforeController.setLooping(true);
    _afterController.setLooping(true);
    
    _beforeController.play();
    _afterController.play();

    setState(() => _isInitialized = true);
  }

  void _synchronize() {
    if (!mounted) return;
    
    // Sync Play/Pause
    if (_beforeController.value.isPlaying != _afterController.value.isPlaying) {
      if (_beforeController.value.isPlaying) {
        _afterController.play();
      } else {
        _afterController.pause();
      }
    }

    // Temporal Sync correction
    final diff = (_beforeController.value.position.inMilliseconds - 
                  _afterController.value.position.inMilliseconds).abs();
    if (diff > 120) {
      _afterController.seekTo(_beforeController.value.position);
    }
  }

  @override
  void dispose() {
    _beforeController.removeListener(_synchronize);
    _beforeController.dispose();
    _afterController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)));
    }

    return Column(
      children: [
        // Premium Mode Selector
        _buildModeSwitcher(),
        
        // Main Viewing Canvas
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.1), blurRadius: 40)
                ],
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildSelectedModeView(),
            ),
          ),
        ),

        // Controls
        _buildPlaybackControls(),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeBtn(ComparisonMode.slider, Icons.unfold_more_rounded, "SLIDER"),
          _modeBtn(ComparisonMode.split, Icons.splitscreen_rounded, "SPLIT"),
          _modeBtn(ComparisonMode.toggle, Icons.swap_horiz_rounded, "TOGGLE"),
        ],
      ),
    );
  }

  Widget _modeBtn(ComparisonMode mode, IconData icon, String label) {
    bool active = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF22D3EE) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.black : Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? Colors.black : Colors.white38,
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

  Widget _buildSelectedModeView() {
    switch (_currentMode) {
      case ComparisonMode.slider: return _buildSliderView();
      case ComparisonMode.split: return _buildSplitView();
      case ComparisonMode.toggle: return _buildToggleView();
    }
  }

  Widget _buildSliderView() {
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
              // Handle
              Positioned(
                left: constraints.maxWidth * _sliderValue - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: const Color(0xFF22D3EE),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                      ),
                      child: const Icon(Icons.unfold_more_rounded, color: Color(0xFF22D3EE), size: 24),
                    ),
                  ),
                ),
              ),
              _badge("BEFORE", Alignment.topLeft),
              _badge("AI ENHANCED", Alignment.topRight, isAccent: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitView() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              SizedBox.expand(child: VideoPlayer(_beforeController)),
              _badge("ORIGINAL", Alignment.topCenter),
            ],
          ),
        ),
        Container(width: 2, color: const Color(0xFF22D3EE)),
        Expanded(
          child: Stack(
            children: [
              SizedBox.expand(child: VideoPlayer(_afterController)),
              _badge("ENHANCED", Alignment.topCenter, isAccent: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleView() {
    return GestureDetector(
      onTap: () => setState(() => _isToggledToAfter = !_isToggledToAfter),
      child: Stack(
        children: [
          SizedBox.expand(
            child: VideoPlayer(_isToggledToAfter ? _afterController : _beforeController),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isToggledToAfter ? const Color(0xFF22D3EE) : Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isToggledToAfter ? "AI ENHANCED" : "ORIGINAL",
                style: TextStyle(
                  color: _isToggledToAfter ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const Center(child: Icon(Icons.touch_app_rounded, color: Colors.white24, size: 80)),
        ],
      ),
    );
  }

  Widget _badge(String text, Alignment align, {bool isAccent = false}) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAccent ? const Color(0xFF22D3EE).withOpacity(0.8) : Colors.black54,
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

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, top: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ctrlBtn(Icons.replay_rounded, () {
            _beforeController.seekTo(Duration.zero);
            _afterController.seekTo(Duration.zero);
          }),
          const SizedBox(width: 40),
          GestureDetector(
            onTap: () => setState(() => _beforeController.value.isPlaying ? _beforeController.pause() : _beforeController.play()),
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFF22D3EE), shape: BoxShape.circle),
              child: Icon(_beforeController.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 48),
            ),
          ),
          const SizedBox(width: 40),
          _ctrlBtn(Icons.fullscreen_rounded, () {
            // Fullscreen logic
          }),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
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