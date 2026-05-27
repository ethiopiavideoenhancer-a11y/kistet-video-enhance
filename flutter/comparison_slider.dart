import 'package:flutter/material.dart';

class ComparisonSlider extends StatefulWidget {
  final Widget beforeWidget;
  final Widget afterWidget;

  const ComparisonSlider({
    super.key,
    required this.beforeWidget,
    required this.afterWidget,
  });

  @override
  State<ComparisonSlider> createState() => _ComparisonSliderState();
}

class _ComparisonSliderState extends State<ComparisonSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
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
              // After (Background)
              SizedBox.expand(child: widget.afterWidget),
              
              // Before (Clipped)
              ClipRect(
                clipper: _SliderClipper(_sliderValue),
                child: SizedBox.expand(child: widget.beforeWidget),
              ),
              
              // Handle
              Positioned(
                left: constraints.maxWidth * _sliderValue - 20,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF22D3EE), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22D3EE).withOpacity(0.5),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: const Icon(Icons.unfold_more_rounded, 
                          color: Color(0xFF22D3EE), 
                          size: 20
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double position;
  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => oldClipper.position != position;
}