import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Width breakpoints. Phones are compact; tablets and small laptops medium.
const compactMax = 700.0;
const expandedMin = 1100.0;

bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < compactMax;
bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expandedMin;

/// Horizontal padding that keeps content at most [maxWidth] wide and centered.
double sidePadding(double screenWidth, {double maxWidth = 1200, double min = 16}) =>
    math.max(min, (screenWidth - maxWidth) / 2);

/// Centers [child] and caps its width, for forms and lists on wide screens.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, this.maxWidth = 900, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}

/// App bar for top-level pages whose content is centered at [maxWidth]; the
/// title lines up with the content's left edge.
AppBar pageAppBar(BuildContext context, String title, {double maxWidth = 900}) {
  final pad = sidePadding(MediaQuery.sizeOf(context).width, maxWidth: maxWidth);
  return AppBar(
    automaticallyImplyLeading: false,
    titleSpacing: pad,
    toolbarHeight: 72,
    title: Text(title),
  );
}
