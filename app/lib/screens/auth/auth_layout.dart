import 'package:flutter/material.dart';

import '../../ui/brand_mark.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';

/// Frame for login, OTP and first-time profile screens: brand panel beside
/// the form on wide screens, brand header above it on phones.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.showBack = false});

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
    );

    if (isCompact(context)) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _BrandPanel(compact: true, showBack: showBack),
            Padding(padding: const EdgeInsets.all(24), child: child),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(children: [
        Expanded(flex: 5, child: _BrandPanel(compact: false, showBack: showBack)),
        Expanded(flex: 4, child: Center(child: form)),
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact, required this.showBack});

  final bool compact;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: Brand.charcoal,
      padding: EdgeInsets.fromLTRB(compact ? 24 : 56, top + (compact ? 16 : 48), compact ? 24 : 56, compact ? 32 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            if (showBack)
              IconButton(
                color: Colors.white,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            BrandMark(onDark: true, size: compact ? 36 : 44),
          ]),
          if (compact) const SizedBox(height: 28),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Sell leftover\nmaterial. Free.',
              style: (compact ? theme.textTheme.headlineMedium : theme.textTheme.displaySmall)
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 20),
            const _Point(Icons.sell_rounded, 'List in 2 minutes. No subscription, no commission for sellers.'),
            const _Point(Icons.shield_rounded, 'Your number stays private until a buyer pays to unlock it.'),
            const _Point(Icons.currency_rupee_rounded, 'Buyers pay a small unlock fee, from just ₹10.'),
          ]),
          if (!compact)
            Text('Cement · Steel · Tiles · Bricks · Plumbing · Electrical · Wood · Paint',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Brand.orange.withAlpha(40), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: Brand.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35)),
          ),
        ),
      ]),
    );
  }
}
