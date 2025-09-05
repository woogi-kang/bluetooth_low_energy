import 'package:flutter/material.dart';

class SignalIndicator extends StatelessWidget {
  final int rssi;
  final double size;
  final Color? color;

  const SignalIndicator({
    super.key,
    required this.rssi,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final signalColor = color ?? _getSignalColor(rssi);
    final signalBars = _getSignalBars(rssi);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: SignalBarsPainter(
          signalBars: signalBars,
          color: signalColor,
        ),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -65) return Colors.lightGreen;
    if (rssi >= -80) return Colors.orange;
    if (rssi >= -95) return Colors.red;
    return Colors.red.shade700;
  }

  int _getSignalBars(int rssi) {
    if (rssi >= -50) return 4; // 매우 강함
    if (rssi >= -65) return 3; // 강함
    if (rssi >= -80) return 2; // 보통
    if (rssi >= -95) return 1; // 약함
    return 0; // 매우 약함
  }
}

class SignalBarsPainter extends CustomPainter {
  final int signalBars;
  final Color color;

  SignalBarsPainter({
    required this.signalBars,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    final inactivePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5;

    const barCount = 4;
    final barWidth = size.width / barCount * 0.6;
    final barSpacing = size.width / barCount * 0.4;

    for (int i = 0; i < barCount; i++) {
      final barHeight = size.height * (i + 1) / barCount;
      final x = i * (barWidth + barSpacing);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(1),
      );

      canvas.drawRRect(
        rect,
        i < signalBars ? paint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SignalBarsPainter oldDelegate) {
    return oldDelegate.signalBars != signalBars || oldDelegate.color != color;
  }
}