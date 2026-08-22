import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'qr_scanner_page.dart';

/// Chooses between the sign-in screen and the collector.
///
/// supabase_flutter restores a saved session at launch, so a returning user goes
/// straight to the collector instead of retyping a password at every event. The
/// stream only drives rebuilds; currentSession is the source of truth.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (BuildContext context, AsyncSnapshot<AuthState> snapshot) {
        final Session? session = Supabase.instance.client.auth.currentSession;
        return session == null ? const LoginPage() : const QrScannerPage();
      },
    );
  }
}
