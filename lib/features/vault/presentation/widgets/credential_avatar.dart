import 'package:flutter/material.dart';

class CredentialAvatar extends StatelessWidget {
  const CredentialAvatar({
    super.key,
    required this.title,
    required this.color,
    this.size = 48,
  });

  final String title;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = title.trim().isEmpty ? '?' : title.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
