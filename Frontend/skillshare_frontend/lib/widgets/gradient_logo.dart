import 'dart:ui';

import 'package:flutter/material.dart';

class GradientLogo extends StatefulWidget {
  const GradientLogo({super.key});

  @override
  State<GradientLogo> createState() => _GradientLogoState();
}

class _GradientLogoState extends State<GradientLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x667C3AED),
                  blurRadius: 26,
                  spreadRadius: 4,
                )
              ],
            ),
          ),
          const Icon(Icons.school_rounded, color: Colors.white, size: 38),
          Positioned(
            top: -2,
            right: -2,
            child: RotationTransition(
              turns: _controller,
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFFFBBF24), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const GradientText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.headlineSmall;
    const gradient =
        LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]);

    return ShaderMask(
      shaderCallback: (bounds) => gradient
          .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(
        text,
        style: base?.copyWith(color: Colors.white),
      ),
    );
  }
}

class FrostedCard extends StatelessWidget {
  final Widget child;

  const FrostedCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0B0B0F) : Colors.white)
                .withOpacity(0.80),
            border: Border.all(color: Colors.white.withOpacity(0.20)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              )
            ],
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }
}
