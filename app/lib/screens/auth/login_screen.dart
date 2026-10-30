import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repository.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+91${_phone.text.trim()}';
    setState(() => _sending = true);
    try {
      await Repository.instance.sendOtp(phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => OtpScreen(phone: phone)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log in or sign up', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('We will send a one-time code to your mobile.',
                style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted)),
            const SizedBox(height: 28),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('🇮🇳 +91', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              validator: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter a valid 10-digit mobile number',
              onFieldSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? SizedBox.square(
                      dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Brand.onPrimary))
                  : const Text('Get OTP'),
            ),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lock_rounded, size: 16, color: Brand.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your number is never shown on listings. Buyers see it only after they pay to unlock.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
