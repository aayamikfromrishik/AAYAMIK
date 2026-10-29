import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../data/demo_repository.dart';
import '../../data/repository.dart';
import '../../ui/theme.dart';
import '../../widgets/common.dart';
import 'auth_layout.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) t.cancel();
      setState(() => _resendIn--);
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    setState(() => _verifying = true);
    try {
      await Repository.instance.verifyOtp(widget.phone, _code.text);
      if (!mounted) return;
      if (demoMode) {
        // No auth stream in demo mode: go straight into the app.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const ProfileGate()),
          (_) => false,
        );
        return;
      }
      // AuthGate rebuilds underneath; drop the login screens on top of it.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      await Repository.instance.sendOtp(widget.phone);
      _startTimer();
      if (mounted) showMessage(context, 'OTP sent again');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthLayout(
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter the code', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Sent to ${widget.phone}', style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted)),
          const SizedBox(height: 28),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, letterSpacing: 14, fontWeight: FontWeight.w700),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            decoration: const InputDecoration(hintText: '······'),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? const SizedBox.square(
                    dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify and continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _resendIn > 0 ? null : _resend,
            child: Text(_resendIn > 0 ? 'Resend code in $_resendIn s' : 'Resend code'),
          ),
        ],
      ),
    );
  }
}
