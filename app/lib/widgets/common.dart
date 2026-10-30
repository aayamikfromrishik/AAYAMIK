import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/errors.dart';
import '../core/format.dart';
import '../data/repository.dart';
import '../ui/theme.dart';

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(friendlyError(error))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Brand.muted),
            const SizedBox(height: 12),
            Text(friendlyError(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message, this.title, this.action});

  final IconData icon;
  final String? title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: Brand.soft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Brand.accent),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(message,
                  textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted)),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// A listing photo from public storage, or a branded placeholder when there is none.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, this.publicPath, this.categoryId, this.fit = BoxFit.cover});

  final String? publicPath;
  final String? categoryId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = LayoutBuilder(
      builder: (context, c) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Brand.soft, Brand.sand],
          ),
        ),
        child: Center(
          child: Icon(
            categoryId == null ? Icons.construction_rounded : categoryById(categoryId!).icon,
            size: (c.biggest.shortestSide * 0.32).clamp(24, 72),
            color: Brand.accent.withAlpha(150),
          ),
        ),
      ),
    );
    if (publicPath == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: Repository.instance.imageUrl(publicPath!),
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'active' => (Brand.greenSoft, Brand.green),
      'sold' => (const Color(0xFFECEAE6), Brand.muted),
      'removed' => (const Color(0xFFFDE8E8), const Color(0xFFB42318)),
      _ => (const Color(0xFFFFF4D6), const Color(0xFF8A5A00)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabels[status] ?? status,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// "🔒 ₹300 to unlock" badge.
class UnlockFeePill extends StatelessWidget {
  const UnlockFeePill({super.key, required this.feeRupees, this.compact = false});

  final int feeRupees;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_rounded, size: compact ? 12 : 14, color: Brand.accent),
        const SizedBox(width: 4),
        Text(
          '${rupees(feeRupees)} to unlock',
          style: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w700, color: Brand.ink),
        ),
      ]),
    );
  }
}

/// White rounded card with an optional heading, used to group form sections and details.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.step, this.subtitle, required this.child, this.padding});

  final String? title;
  final int? step;
  final String? subtitle;
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(children: [
                if (step != null) ...[
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Brand.header, shape: BoxShape.circle),
                    child: Text('$step',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(title!, style: theme.textTheme.titleMedium)),
              ]),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted)),
              ],
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Runs [task] behind a blocking progress dialog showing [message].
Future<T> withProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ]),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
