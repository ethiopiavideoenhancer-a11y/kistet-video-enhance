import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CloudLibraryScreen extends StatelessWidget {
  const CloudLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            expandedHeight: 120,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('CLOUD LIBRARY', 
                style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: -1, fontStyle: FontStyle.italic)
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _VideoCard(),
                childCount: 5,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 130,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300'),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill_rounded, color: Color(0xFF22D3EE), size: 48),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF22D3EE).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('4K PRO', style: TextStyle(color: Color(0xFF22D3EE), fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Portrait_Test.mp4', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16), maxLines: 1),
                  const Text('Processed: Oct 24', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const Spacer(),
                  Row(
                    children: [
                      _SmallAction(Icons.share, Colors.white24),
                      const SizedBox(width: 8),
                      _SmallAction(Icons.delete_outline, Colors.redAccent.withOpacity(0.1), iconColor: Colors.redAccent),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  const _SmallAction(this.icon, this.bg, {this.iconColor = Colors.white54});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: iconColor, size: 16),
    );
  }
}