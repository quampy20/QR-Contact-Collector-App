import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final List<String> _tags = ['Student', 'Employee Prospect', 'Business Contact', 'Friend'];
  String _selectedTag = 'Employee Prospect';
  late String _sessionId;

  // No trailing slash: _qrDataUrl adds the "/" itself.
  final String _baseWebUrl = "https://qr-contact-collector-app.vercel.app";

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _sessionId = const Uuid().v4();
  }

  String get _qrDataUrl {
    return "$_baseWebUrl/?sid=$_sessionId&tag=${Uri.encodeComponent(_selectedTag)}";
  }

  void _showContactDetailsDialog(Map<String, dynamic> contact, Object rowId) {
    TextEditingController notesController = TextEditingController(text: contact['notes'] ?? '');
    String currentTag = contact['tag'] ?? _selectedTag;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contact['name'] ?? 'Unknown Name'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Email: ${contact['email'] ?? 'N/A'}"),
                Text("Phone: ${contact['phone'] ?? 'N/A'}"),
                const Divider(),
                ...contact.entries.where((e) =>
                  !['id', 'session_id', 'name', 'email', 'phone', 'tag', 'created_at', 'notes'].contains(e.key)
                  && e.value != null
                  && e.value.toString().isNotEmpty
                ).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text("${e.key.toUpperCase()}: ${e.value}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                  );
                }),
                const Divider(),
                DropdownButtonFormField<String>(
                  initialValue: currentTag,
                  items: _tags.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) {
                    if (val != null) currentTag = val;
                  },
                  decoration: const InputDecoration(labelText: "Adjust Tag"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Private Notes",
                    border: OutlineInputBorder(),
                  ),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('contacts').update({
                  'tag': currentTag,
                  'notes': notesController.text,
                }).eq('id', rowId);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    ).whenComplete(notesController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Collect Contacts', style: TextStyle(color: Colors.black87)), backgroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tags.map((tag) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (selected) { if (selected) setState(() => _selectedTag = tag); },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Text("Scan as: ${_selectedTag.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  QrImageView(data: _qrDataUrl, size: 260.0, backgroundColor: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text("Recent Scans (Live)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase
                          .from('contacts')
                          .stream(primaryKey: ['id'])
                          .eq('session_id', _sessionId)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final contacts = snapshot.data!;
                        if (contacts.isEmpty) return const Center(child: Text("Waiting for scans..."));

                        return ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            var contact = contacts[index];
                            bool hasNotes = contact['notes'] != null && contact['notes'].toString().isNotEmpty;

                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(contact['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(contact['email'] ?? contact['phone'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasNotes) const Icon(Icons.note_alt, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Chip(label: Text(contact['tag'] ?? 'Tag', style: const TextStyle(fontSize: 10))),
                                ],
                              ),
                              onTap: () => _showContactDetailsDialog(contact, contact['id']),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
