import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeatherBackground extends StatefulWidget {
  final String weather;

  const WeatherBackground({super.key, required this.weather});

  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WeatherPainter(
            weather: widget.weather,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}


class WeatherPainter extends CustomPainter {
  final String weather;
  final double animationValue;

  WeatherPainter({required this.weather, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.shade800;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant WeatherPainter oldDelegate) =>
      oldDelegate.weather != weather || oldDelegate.animationValue != animationValue;
}