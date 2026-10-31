import 'package:flutter/material.dart';

import 'theme.dart';

/// The BAAKI BUILD logo: the pin-and-bricks mark beside the wordmark.
/// Brick mark with forest-green lettering on light backgrounds; cream mark
/// and lettering on the green header (the logo's "Cream" colourway).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 40, this.showTagline = true});

  final bool onDark;

  /// Height of the pin mark; the wordmark scales with it.
  final double size;
  final bool showTagline;

  static const _cream = Color(0xFFFAF6F1);

  @override
  Widget build(BuildContext context) {
    final lettering = onDark ? _cream : Brand.header;
    return Semantics(
      label: 'BAAKI BUILD by AAYAMIK',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            onDark ? 'assets/brand/mark_cream.png' : 'assets/brand/mark_brick.png',
            height: size * 1.15,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(width: size * 0.26),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BAAKI BUILD',
                style: TextStyle(
                  fontFamily: Brand.font,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.5,
                  height: 1.05,
                  color: lettering,
                ),
              ),
              if (showTagline)
                Padding(
                  padding: EdgeInsets.only(top: size * 0.06),
                  child: Text(
                    'BY AAYAMIK',
                    style: TextStyle(
                      fontFamily: Brand.font,
                      fontWeight: FontWeight.w600,
                      fontSize: size * 0.22,
                      letterSpacing: size * 0.075,
                      color: lettering,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
