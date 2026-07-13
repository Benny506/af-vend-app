import 'package:flutter/material.dart';

class SignInMedusaLogo extends StatefulWidget {
  const SignInMedusaLogo({super.key, this.rotate = false});

  final bool rotate;

  @override
  State<SignInMedusaLogo> createState() => _SignInMedusaLogoState();
}

class _SignInMedusaLogoState extends State<SignInMedusaLogo>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    if (widget.rotate) {
      _controller.repeat(reverse: true);
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SignInMedusaLogo oldWidget) {
    if (oldWidget.rotate != widget.rotate) {
      if (widget.rotate) {
        _controller.repeat(reverse: true);
      } else {
        _controller.reverse();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.rotate ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
      child: Hero(
        tag: 'app_logo',
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/square_logo.png',
              height: 100,
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
