import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color? dynamicColor;

  const GradientBackground({super.key, required this.child, this.dynamicColor});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black, child: child);
  }
}
