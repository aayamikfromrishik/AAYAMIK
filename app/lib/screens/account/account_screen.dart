import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import '../auth/profile_setup_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _repo = Repository.instance;
  late Future<(Profile?, String?)> _future = _load();

  Future<(Profile?, String?)> _load() async => (await _repo.myProfile(), await _repo.myPhone());

  Future<void> _editProfile(Profile profile) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => ProfileSetupScreen(existing: profile, onSaved: () => Navigator.pop(context)),
    ));
    setState(() => _future = _load());
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) await _repo.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = sidePadding(MediaQuery.sizeOf(context).width, maxWidth: 900);
    return Scaffold(
      appBar: pageAppBar(context, 'Account'),
      body: FutureBuilder<(Profile?, String?)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: () => setState(() => _future = _load()));
          }
          final (profile, phone) = snap.data!;
          final name = profile?.displayName ?? '';
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 4, pad, 32),
            children: [
              Card(
                color: Brand.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Brand.orange,
                      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text([if (phone != null) formatPhone(phone), ?profile?.city].join('  ·  '),
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                      ]),
                    ),
                    if (profile != null)
                      IconButton(
                        tooltip: 'Edit profile',
                        color: Colors.white,
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _editProfile(profile),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'How it works',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const _Point(Icons.sell_rounded, 'Listing is free. No subscription, no commission for sellers.'),
                  const _Point(Icons.lock_rounded, "Buyers pay a small fee to see the seller's phone and exact address."),
                  const _Point(Icons.replay_rounded, 'Refund within 7 days if already sold, or no reply in 48 hours.'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Table(
                      border: const TableBorder(horizontalInside: BorderSide(color: Brand.line)),
                      children: const [
                        TableRow(
                          decoration: BoxDecoration(color: Brand.sand),
                          children: [_Cell('Listed price', bold: true), _Cell('Unlock fee', bold: true)],
                        ),
                        TableRow(children: [_Cell('Up to ₹1,000'), _Cell('₹10')]),
                        TableRow(children: [_Cell('₹1,001 – ₹50,000'), _Cell('1% of price')]),
                        TableRow(children: [_Cell('₹50,001 – ₹1,00,000'), _Cell('₹500')]),
                        TableRow(children: [_Cell('Above ₹1,00,000'), _Cell('₹1,000')]),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              const SectionCard(
                title: 'Listing rules',
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _Point(Icons.phone_disabled_rounded, 'No phone numbers, emails, links or "WhatsApp me" in text.'),
                  _Point(Icons.no_photography_rounded,
                      'Photos show only the material: no faces, no QR codes, no numbers.'),
                  _Point(Icons.price_check_rounded,
                      'List the real price. Listings reported for a different price are removed.'),
                ]),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: Brand.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ]),
      );
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(text, style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null),
      );
}
