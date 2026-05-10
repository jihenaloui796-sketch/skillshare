import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    return SizedBox(
      height: 44,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(colors: [Color(0xFFBDBDBD), Color(0xFFBDBDBD)])
              : const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: disabled
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x667C3AED),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: disabled ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
