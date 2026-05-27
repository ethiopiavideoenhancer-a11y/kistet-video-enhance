import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'before_after_player.dart';

class EnhancementPreviewScreen extends StatelessWidget {
  final String originalUrl;
  final String enhancedUrl;

  const EnhancementPreviewScreen({
    super.key,
    required this.originalUrl,
    required this.enhancedUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Tech Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://storage.googleapis.com/dala-prod-public-storage/generated-images/9e90f1ee-593f-4399-b5b3-afb9cb1d441d/bluerays-dashboard-09440b80-1779866697325.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Header
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                ),
                Text(
                  'COMPARE QUALITY',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 44), // Spacer for balance
              ],
            ),
          ),

          // Main Comparison Player
          Positioned.fill(
            top: 140,
            child: BeforeAfterPlayer(
              beforeUrl: originalUrl,
              afterUrl: enhancedUrl,
            ),
          ),

          // Watermark / Unlock Panel
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_rounded, color: Color(0xFF8B5CF6), size: 24),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          "Watermark is visible in free preview.",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // Start Payment / HD Export Flow
                  },
                  child: Container(
                    width: double.infinity,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PAY TO UNLOCK HD EXPORT',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}