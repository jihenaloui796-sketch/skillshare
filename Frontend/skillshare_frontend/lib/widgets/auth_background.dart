import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final begin = isDark
        ? const [Color(0xFF0F172A), Color(0xFF1F1146), Color(0xFF1D0D2E)]
        : const [Color(0xFFF5F3FF), Color(0xFFF3E8FF), Color(0xFFFDF4FF)];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final scale1 = 1 + 0.2 * math.sin(t * 2 * math.pi);
        final scale2 = 1 + 0.2 * math.sin((t + 0.5) * 2 * math.pi);
        final opacity1 = isDark ? 0.18 : 0.30;
        final opacity2 = isDark ? 0.18 : 0.30;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: begin,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -180,
                right: -180,
                child: Transform.scale(
                  scale: scale1,
                  child: _Blob(
                    color: (isDark
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF8B5CF6))
                        .withOpacity(opacity1),
                  ),
                ),
              ),
              Positioned(
                bottom: -180,
                left: -180,
                child: Transform.scale(
                  scale: scale2,
                  child: _Blob(
                    color: (isDark
                            ? const Color(0xFFDB2777)
                            : const Color(0xFFD946EF))
                        .withOpacity(opacity2),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: widget.child,
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
}

class _Blob extends StatelessWidget {
  final Color color;

  const _Blob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: const SizedBox.expand(),
      ),
    );
  }
}
