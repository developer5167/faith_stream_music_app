import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showTagline;
  final TextAlign textAlign;
  final bool useGradient;

  const AppLogo({
    super.key,
    this.fontSize = 24,
    this.showTagline = false,
    this.textAlign = TextAlign.center,
    this.useGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: textAlign == TextAlign.center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Faith',
              style: GoogleFonts.figtree(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (useGradient)
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppTheme.brandPurple,
                    AppTheme.brandMagenta,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Stream',
                  style: GoogleFonts.figtree(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              )
            else
              Text(
                'Stream',
                style: GoogleFonts.figtree(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'Grace in Every Stream',
            style: GoogleFonts.figtree(
              fontSize: fontSize * 0.4,
              color: Colors.white70,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w300,
            ),
            textAlign: textAlign,
          ),
        ],
      ],
    );
  }
}
