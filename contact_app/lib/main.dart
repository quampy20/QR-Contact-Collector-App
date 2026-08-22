import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';

/// Supabase project credentials.
///
/// The anon key is a publishable client key: it is meant to ship inside client
/// applications, and every table it can reach must be protected by Row Level
/// Security policies rather than by keeping this string secret.
const String supabaseUrl = 'https://tyqundkujjkqirbosxfv.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5cXVuZGt1amprcWlyYm9zeGZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczNDg1NTYsImV4cCI6MjEwMjkyNDU1Nn0.Eh7LTwMIgayAVKLsGvwgxcmj9UJOB6yj7WT9rhrtcoU';

/// Shorthand for the initialised Supabase client.
///
/// Top-level finals are lazy in Dart, so this is only resolved on first use —
/// after [Supabase.initialize] has completed in [main].
final SupabaseClient supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ContactApp());
}

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Collector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      ),
      home: const AuthGate(),
    );
  }
}
