import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:sonner/sonner.dart';
import 'result_screen.dart';

class VideoDetailsScreen extends StatefulWidget {
  final String videoId; // Changed from videoUrl to videoId for proper polling
  final String videoUrl;
  final Map<String, dynamic> metadata;

  const VideoDetailsScreen({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.metadata,
  });

  @override
  State<VideoDetailsScreen> createState() => _VideoDetailsScreenState();
}

class _VideoDetailsScreenState extends State<VideoDetailsScreen> {
  late VideoPlayerController _controller;
  bool _isProcessing = false;
  String _statusMessage = 'READY TO ENHANCE';

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startEnhancement() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'INITIALIZING GPU...';
    });

    try {
      final dio = Dio();
      // Step 1: Trigger Enhancement
      final response = await dio.post(
        'http://localhost:8000/videos/enhance',
        data: {
          'video_id': widget.videoId,
          'user_id': 1, // Mock user ID
          'options': {'upscale': true, 'face': true}
        },
      );

      if (response.statusCode == 200) {
        toast.info('Enhancement started. This may take a minute.');
        _pollStatus();
      } else {
        throw Exception('Failed to start enhancement');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'ENHANCEMENT FAILED';
      });
      toast.error('Error: $e');
    }
  }

  Future<void> _pollStatus() async {
    final dio = Dio();
    bool isComplete = false;

    while (!isComplete && mounted) {
      try {
        await Future.delayed(const Duration(seconds: 3));
        final response = await dio.get('http://localhost:8000/videos/${widget.videoId}');
        
        if (response.statusCode == 200) {
          final data = response.data;
          final status = data['status'];
          
          setState(() {
            _statusMessage = status == 'processing' ? 'PROCESSING AI MODELS...' : 'FINALIZING CLOUD UPLOAD...';
          });

          if (data['success'] == true) {
            isComplete = true;
            if (!mounted) return;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultScreen(videoData: data),
              ),
            ).then((_) => setState(() => _isProcessing = false));
          } else if (status == 'failed') {
            throw Exception('AI Processing failed on server');
          }
        }
      } catch (e) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'ERROR IN PIPELINE';
        });
        toast.error('Polling error: $e');
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('ORIGINAL VIDEO', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
      ),
      body: Column(
        children: [
          // Player
          AspectRatio(
            aspectRatio: _controller.value.isInitialized ? _controller.value.aspectRatio : 16/9,
            child: _controller.value.isInitialized 
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    GestureDetector(
                      onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.white.withOpacity(0.8),
                        size: 64,
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE))),
          ),
          
          // Metadata
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VIDEO INFORMATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, color: const Color(0xFF22D3EE))),
                  const SizedBox(height: 20),
                  _metadataRow(Icons.aspect_ratio, 'Resolution', widget.metadata['resolution'] ?? '1080x1920'),
                  _metadataRow(Icons.speed, 'FPS', '${widget.metadata['fps'] ?? 30} FPS'),
                  _metadataRow(Icons.storage, 'File Size', widget.metadata['file_size'] ?? '42.5 MB'),
                  _metadataRow(Icons.timer, 'Duration', '${widget.metadata['duration'] ?? 12.5}s'),
                  
                  const Spacer(),
                  
                  // Status Display
                  if (_isProcessing)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _statusMessage,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF22D3EE),
                            fontSize: 12,
                            fontWeight: FontWeight.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  
                  // Action Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _startEnhancement,
                    child: Container(
                      width: double.infinity,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Center(
                        child: _isProcessing 
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('ENHANCE VIDEO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}