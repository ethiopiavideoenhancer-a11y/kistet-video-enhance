import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_react/lucide_react.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sonner/sonner.dart';
import 'package:video_player/video_player.dart';
import 'package:open_file/open_file.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const ResultScreen({super.key, required this.videoData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late VideoPlayerController _controller;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    final url = widget.videoData['enhanced_video_url'] ?? widget.videoData['preview_video_url'];
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final downloadUrl = widget.videoData['download_url'];
    if (downloadUrl == null) {
      toast.error('Download link missing');
      return;
    }

    // 1. Request Permissions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final extStatus = await Permission.manageExternalStorage.request();
        if (!extStatus.isGranted) {
          toast.error('Storage permission denied');
          return;
        }
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      
      // 2. Get Save Path
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'bluerays_enhanced_${widget.videoData['video_id']}.mp4';
      final savePath = '${directory!.path}/$fileName';

      // 3. Start Download
      debugPrint('Downloading from $downloadUrl to $savePath');
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // 4. Verify Download
      final file = File(savePath);
      if (await file.exists() && await file.length() > 0) {
        setState(() {
          _localFilePath = savePath;
          _isDownloading = false;
        });
        toast.success('Download Complete! Saved to: $savePath');
      } else {
        throw Exception('File verification failed: File empty or missing after download');
      }

    } catch (e) {
      debugPrint('Download error: $e');
      setState(() => _isDownloading = false);
      
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          toast.error('Network timeout. Please check your connection.');
        } else {
          toast.error('Server error: ${e.message}');
        }
      } else {
        toast.error('Download failed. Please ensure you have enough storage.');
      }
    }
  }

  void _openFile() {
    if (_localFilePath != null) {
      OpenFile.open(_localFilePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
            title: Text(
              'ENHANCEMENT READY',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: const Color(0xFF22D3EE),
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Video Player
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: _controller.value.isInitialized ? _controller.value.aspectRatio : 9/16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _controller.value.isInitialized
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_controller),
                                _buildPlayPauseOverlay(),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE))),
                    ),
                  ),
                ),

                // Action Center
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      if (_localFilePath == null)
                        _buildDownloadButton()
                      else
                        _buildOpenButton(),
                      
                      const SizedBox(height: 16),
                      
                      _buildSecondaryAction(
                        label: 'WATCH VIDEO',
                        icon: LucideIcons.play,
                        onTap: () => setState(() => _controller.play()),
                      ),
                      const SizedBox(height: 12),
                      _buildSecondaryAction(
                        label: 'SAVE TO CLOUD',
                        icon: LucideIcons.cloud,
                        onTap: () => toast.success('Saved to your cloud history'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return GestureDetector(
      onTap: _isDownloading ? null : _handleDownload,
      child: Container(
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isDownloading)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _downloadProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isDownloading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(LucideIcons.download, color: Colors.black, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isDownloading 
                    ? 'DOWNLOADING ${(_downloadProgress * 100).toInt()}%' 
                    : 'DOWNLOAD HD VIDEO',
                  style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenButton() {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.externalLink, color: Colors.black),
            const SizedBox(width: 12),
            Text(
              'OPEN ENHANCED FILE',
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AnimatedOpacity(
            opacity: _controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(LucideIcons.play, color: Colors.white, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}