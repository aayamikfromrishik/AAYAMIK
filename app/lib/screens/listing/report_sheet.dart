import 'package:flutter/material.dart';

import '../../data/repository.dart';
import '../../widgets/common.dart';

/// Values of the `report_reason` enum.
const _reasons = {
  'price_mismatch': 'Price is different from the listing',
  'contact_details_in_listing': 'Shows phone number or contact details',
  'fake_listing': 'Fake or misleading listing',
  'already_sold': 'Already sold',
  'offensive': 'Offensive content',
  'other': 'Something else',
};

Future<void> showReportSheet(BuildContext context, String listingId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(listingId: listingId),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.listingId});

  final String listingId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await Repository.instance.report(widget.listingId, _reason!, _details.text);
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, 'Thanks. We will review this listing.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Report listing', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(children: [
                  for (final e in _reasons.entries)
                    RadioListTile<String>(value: e.key, title: Text(e.value), contentPadding: EdgeInsets.zero),
                ]),
              ),
              TextField(
                controller: _details,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(labelText: 'More details (optional)'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _reason == null || _sending ? null : _send,
                child: const Text('Send report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
