
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'data_entry_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0014),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1F0638),
                  Color(0xFF0A0014),
                ],
              ),
            ),
          ),

          Positioned(
            top: -140,
            left: -170,
            child: _circle(
              480,
              const Color(0x331A0B3D),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -160,
            child: _circle(
              420,
              const Color(0x44301048),
            ),
          ),

          const Positioned.fill(
            child: FloatingDecorations(),
          ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 7),

                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Image.asset(
                    'assets/images/logo_transparent.png',
                    width: 300,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.child_care,
                        size: 100,
                        color: Colors.white,
                      );
                    },
                  ),
                ),

                const Spacer(flex: 4),

                _StartButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DataEntryScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 22),

                
            

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC94FD8),
            Color(0xFFFF4D9D),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66E040FB),
            blurRadius: 30,
            spreadRadius: 1,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: const Center(
            child: Text(
              "Let's Start Journey",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingDecorations extends StatefulWidget {
  const FloatingDecorations({super.key});

  @override
  State<FloatingDecorations> createState() =>
      _FloatingDecorationsState();
}

class _FloatingDecorationsState
    extends State<FloatingDecorations>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value * 2 * math.pi;

              Widget item(
                String symbol,
                double x,
                double y,
                double phase, {
                double size = 22,
              }) {
                final wave = math.sin(t + phase);

                return Positioned(
                  left: width * x,
                  top: height * y + wave * 16,
                  child: Opacity(
                    opacity: 0.12 +
                        0.10 *
                            ((math.sin(t + phase) + 1) / 2),
                    child: Transform.rotate(
                      angle: wave * 0.12,
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: size,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  item('✦', 0.12, 0.16, 0, size: 24),
                  item('✧', 0.78, 0.12, 1.2, size: 28),
                  item('✦', 0.84, 0.43, 2.4),
                  item('✧', 0.18, 0.60, 3.2, size: 25),
                  item('✦', 0.48, 0.25, 4.1, size: 18),
                  item('✧', 0.68, 0.76, 5.0),
                  item('🍼', 0.08, 0.37, 1.5, size: 25),
                  item('🍼', 0.80, 0.65, 3.8, size: 23),
                  item('♡', 0.82, 0.25, 2.8, size: 28),
                  item('♡', 0.12, 0.78, 4.5, size: 28),
                  item('◉', 0.88, 0.82, 1.8, size: 18),
                  item('·', 0.35, 0.45, 2.1, size: 30),
                  item('✦', 0.55, 0.85, 3.5, size: 20),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
