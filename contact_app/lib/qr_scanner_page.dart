import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Shows a QR code that visitors scan to reach the hosted contact form, and
/// lists the contacts that come back for the current session.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  /// Deployed web form that the QR code points at.
  static const String _baseWebUrl =
      'https://qr-contact-collector-app.vercel.app/';

  /// Tags the web form branches on when choosing its extra questions.
  static const List<String> _tags = <String>[
    'Student',
    'Employee Prospect',
    'Business Contact',
    'Friend',
  ];

  /// Columns the form writes for bookkeeping rather than for display.
  static const Set<String> _hiddenColumns = <String>{
    'id',
    'session_id',
    'created_at',
    'name',
    'email',
    'phone',
    'tag',
  };

  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  late String _sessionId;
  late Stream<List<Map<String, dynamic>>> _contacts;
  String _tag = _tags.first;

  @override
  void initState() {
    super.initState();
    _sessionId = _uuid.v4();
    _bindContactsStream();
  }

  /// (Re)subscribes to the rows this session has collected. Held in a field so
  /// that a rebuild does not tear down and recreate the subscription.
  void _bindContactsStream() {
    _contacts = _supabase
        .from('contacts')
        .stream(primaryKey: <String>['id'])
        .eq('session_id', _sessionId)
        .order('created_at');
  }

  /// The URL encoded into the QR code — the form plus the `sid` and `tag`
  /// query parameters it reads on load.
  String get _shareUrl => Uri.parse(_baseWebUrl).replace(
        queryParameters: <String, String>{'sid': _sessionId, 'tag': _tag},
      ).toString();

  void _startNewSession() {
    setState(() {
      _sessionId = _uuid.v4();
      _bindContactsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Collector'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New session',
            onPressed: _startNewSession,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildTagSelector(theme),
          const SizedBox(height: 16),
          _buildQrCard(theme),
          const SizedBox(height: 24),
          Text('Collected contacts', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildContactList(theme),
        ],
      ),
    );
  }

  Widget _buildTagSelector(ThemeData theme) {
    return DropdownButtonFormField<String>(
      initialValue: _tag,
      decoration: const InputDecoration(
        labelText: 'Collecting as',
        border: OutlineInputBorder(),
      ),
      items: <DropdownMenuItem<String>>[
        for (final String tag in _tags)
          DropdownMenuItem<String>(value: tag, child: Text(tag)),
      ],
      onChanged: (String? value) {
        if (value != null) {
          setState(() => _tag = value);
        }
      },
    );
  }

  Widget _buildQrCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            Text(
              'Scan to share your details',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // A white backdrop keeps the code scannable under a dark theme.
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                data: _shareUrl,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _shareUrl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList(ThemeData theme) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _contacts,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Could not load contacts: ${snapshot.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final List<Map<String, dynamic>> contacts = snapshot.data!;
        if (contacts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Nothing collected yet — the first scan will show up here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        return Column(
          children: <Widget>[
            for (final Map<String, dynamic> contact in contacts)
              _buildContactTile(theme, contact),
          ],
        );
      },
    );
  }

  Widget _buildContactTile(ThemeData theme, Map<String, dynamic> contact) {
    // The form writes a different set of columns per tag, so render whatever
    // came back rather than a fixed field list.
    final List<String> extras = <String>[
      for (final MapEntry<String, dynamic> entry in contact.entries)
        if (!_hiddenColumns.contains(entry.key) &&
            entry.value != null &&
            entry.value.toString().isNotEmpty)
          '${entry.key.replaceAll('_', ' ')}: ${entry.value}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(contact['name']?.toString() ?? 'Unnamed contact'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final String field in <String>['email', 'phone'])
              if (contact[field] != null &&
                  contact[field].toString().isNotEmpty)
                Text(contact[field].toString()),
            if (extras.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  extras.join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
        trailing: contact['tag'] == null
            ? null
            : Chip(label: Text(contact['tag'].toString())),
        isThreeLine: extras.isNotEmpty,
      ),
    );
  }
}
