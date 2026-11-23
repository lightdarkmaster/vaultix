import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 120});

  final int score;
  final double size;

  static Color colorFor(int score) => score >= 80
      ? AppColors.success
      : score >= 50
          ? AppColors.warning
          : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(score);
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: score / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CircularProgressIndicator(
                value: v,
                strokeWidth: size * 0.09,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                      fontSize: size * 0.32, fontWeight: FontWeight.w800)),
              Text('out of 100',
                  style: TextStyle(fontSize: size * 0.1, color: muted)),
            ],
          ),
        ],
      ),
    );
  }
}
