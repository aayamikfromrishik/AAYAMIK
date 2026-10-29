import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/repository.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  title: Text(profile?.displayName ?? '', style: theme.textTheme.titleMedium),
                  subtitle: Text([?phone, ?profile?.city].join('  ·  ')),
                  trailing: profile == null
                      ? null
                      : IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editProfile(profile)),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('How it works', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('• Listing is free. No subscription.'),
                    const Text('• Buyers pay a small fee to see the seller\'s phone and exact address.'),
                    const Text('• Refund within 7 days if already sold, or no reply in 48 hours.'),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: theme.colorScheme.outlineVariant),
                      children: const [
                        TableRow(children: [_Cell('Listed price', bold: true), _Cell('Unlock fee', bold: true)]),
                        TableRow(children: [_Cell('Up to ₹1,000'), _Cell('₹10')]),
                        TableRow(children: [_Cell('₹1,001 – ₹50,000'), _Cell('1%')]),
                        TableRow(children: [_Cell('₹50,001 – ₹1,00,000'), _Cell('₹500')]),
                        TableRow(children: [_Cell('Above ₹1,00,000'), _Cell('₹1,000')]),
                      ],
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Listing rules', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text('• No phone numbers, emails, links or "WhatsApp me" in text.'),
                    const Text('• Photos must show only the material: no faces, no QR codes, no numbers.'),
                    const Text('• List the real price. Listings reported for a different price are removed.'),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null),
      );
}
