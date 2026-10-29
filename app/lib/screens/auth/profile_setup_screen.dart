import 'package:flutter/material.dart';

import '../../core/contact_filter.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../ui/layout.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

/// First-time setup, and later editing from the Account tab.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.onSaved, this.existing});

  final VoidCallback onSaved;
  final Profile? existing;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.displayName);
  late final _city = TextEditingController(text: widget.existing?.city);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Repository.instance.saveProfile(displayName: _name.text, city: _city.text);
      widget.onSaved();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _noContact(String? v) =>
      containsContactInfo(v) ? 'Phone numbers, emails and links are not allowed' : null;

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final theme = Theme.of(context);
    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editing) ...[
            Text('Welcome!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Tell other builders who you are. This name is shown on your listings.',
                style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted)),
            const SizedBox(height: 28),
          ],
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name or company name',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.length < 2) return 'Enter at least 2 characters';
              if (t.length > 60) return 'Keep it under 60 characters';
              return _noContact(t);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'City (optional)',
              prefixIcon: Icon(Icons.location_city_rounded),
            ),
            validator: _noContact,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(editing ? 'Save' : 'Continue'),
          ),
        ],
      ),
    );

    if (!editing) return AuthLayout(child: form);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MaxWidth(maxWidth: 560, child: SectionCard(child: form)),
      ),
    );
  }
}
