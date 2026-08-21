// Smoke test for the app shell.
//
// Pumping the full widget tree needs a live Supabase client, since
// QrScannerPage resolves Supabase.instance.client when it initialises. This
// test therefore stays at construction level; add a mocked Supabase client
// before writing tests that pump ContactApp.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:contact_app/main.dart';

void main() {
  test('ContactApp constructs without touching Supabase', () {
    expect(const ContactApp(), isA<Widget>());
  });

  test('Supabase credentials are configured', () {
    expect(supabaseUrl, startsWith('https://'));
    expect(supabaseAnonKey, isNotEmpty);
  });
}
