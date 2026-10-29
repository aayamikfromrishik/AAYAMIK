import 'package:flutter/material.dart';

import 'theme.dart';

/// Logo: orange tile with a foundation glyph, plus the BAAKI BUILD wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 40, this.showTagline = true});

  final bool onDark;
  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final text = onDark ? Colors.white : Brand.charcoal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: Brand.orange, borderRadius: BorderRadius.circular(size * 0.28)),
          child: Icon(Icons.foundation, color: Colors.white, size: size * 0.6),
        ),
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BAAKI BUILD',
              style: TextStyle(
                fontFamily: Brand.font,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.48,
                letterSpacing: 0.6,
                height: 1.05,
                color: text,
              ),
            ),
            if (showTagline)
              Text(
                'by AAYAMIK',
                style: TextStyle(
                  fontFamily: Brand.font,
                  fontWeight: FontWeight.w600,
                  fontSize: size * 0.26,
                  letterSpacing: 1.2,
                  color: onDark ? Colors.white70 : Brand.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
