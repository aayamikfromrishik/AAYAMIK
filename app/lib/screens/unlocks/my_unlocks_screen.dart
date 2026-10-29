import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../ui/layout.dart';
import '../../widgets/common.dart';
import '../listing/listing_detail_screen.dart';

class MyUnlocksScreen extends StatefulWidget {
  const MyUnlocksScreen({super.key});

  @override
  State<MyUnlocksScreen> createState() => _MyUnlocksScreenState();
}

class _MyUnlocksScreenState extends State<MyUnlocksScreen> {
  late Future<List<Unlock>> _future = Repository.instance.myUnlocks();

  Future<void> _refresh() async {
    final future = Repository.instance.myUnlocks();
    setState(() => _future = future);
    await future;
  }

  Future<void> _askRefund(Unlock unlock) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(title: Text('Why do you want a refund?')),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Material was already sold'),
            onTap: () => Navigator.pop(context, 'already_sold'),
          ),
          ListTile(
            leading: const Icon(Icons.phone_missed_outlined),
            title: const Text('Seller did not respond in 48 hours'),
            onTap: () => Navigator.pop(context, 'seller_no_response'),
          ),
        ]),
      ),
    );
    if (reason == null) return;
    try {
      await Repository.instance.requestRefund(unlock.id, reason);
      if (mounted) showMessage(context, 'Refund requested. We will review it within 2 working days.');
      _refresh();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: pageAppBar(context, 'Unlocked'),
      body: FutureBuilder<List<Unlock>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return ErrorView(error: snap.error!, onRetry: _refresh);
          final unlocks = snap.data!;
          if (unlocks.isEmpty) {
            return const EmptyView(
              icon: Icons.lock_open_rounded,
              title: 'No unlocks yet',
              message: 'When you unlock a listing, the seller\'s phone and address are saved here.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 900), 4,
                  sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 900), 24),
              itemCount: unlocks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _item(unlocks[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _item(Unlock u) {
    final theme = Theme.of(context);
    final canRefund = u.status == 'paid' && u.refundStatus == null;
    final note = switch ((u.status, u.refundStatus)) {
      ('refunded', _) => 'Refunded',
      ('duplicate_paid', _) => 'Paid twice. Extra payment will be refunded',
      (_, 'pending') => 'Refund requested',
      (_, 'rejected') => 'Refund declined',
      _ => null,
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        title: Text(u.listingTitle ?? 'Listing', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (u.listingCity != null) Text(u.listingCity!),
          Text('Paid ${rupees(u.feeRupees)} on ${shortDate(u.paidAt ?? u.createdAt)}'),
          if (u.listingStatus == 'sold') const Text('Seller marked this sold'),
          if (note != null)
            Text(note, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ]),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ListingDetailScreen(listingId: u.listingId)),
        ),
        trailing: canRefund
            ? PopupMenuButton<String>(
                onSelected: (_) => _askRefund(u),
                itemBuilder: (_) => const [PopupMenuItem(value: 'refund', child: Text('Ask for refund'))],
              )
            : null,
      ),
    );
  }
}
