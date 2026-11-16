import 'package:flutter/material.dart';

import '../../core/support_outbox.dart';
import '../../core/widgets/app_scaffold.dart';

enum _RequestType {
  feedback('Feedback'),
  bug('Bug Report'),
  contact('Contact');

  const _RequestType(this.label);
  final String label;
}

class HelpFeedbackScreen extends StatefulWidget {
  const HelpFeedbackScreen({super.key});

  @override
  State<HelpFeedbackScreen> createState() => _HelpFeedbackScreenState();
}

class _HelpFeedbackScreenState extends State<HelpFeedbackScreen> {
  final _form = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _email = TextEditingController();
  var _type = _RequestType.feedback;
  String? _section;
  var _busy = false;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send(SupportOutbox outbox) async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final email = _email.text.trim();
      await outbox.feedback(
        type: _type.name,
        message: _message.text.trim(),
        email: email.isEmpty ? null : email,
        section: _type == _RequestType.bug ? _section : null,
      );
      if (!mounted) return;
      _message.clear();
      FocusScope.of(context).unfocus();
      _notice('Request saved to the outbox.');
    } catch (_) {
      if (mounted) _notice('Could not save your request. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outbox = SupportOutbox.current;
    return AppScaffold(
      title: 'Help & Feedback',
      maxWidth: 680,
      body: outbox == null
          ? const Center(child: Text('Local outbox unavailable.'))
          : ValueListenableBuilder(
              valueListenable: outbox.updates,
              builder: (context, _, child) => Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    DropdownButtonFormField<_RequestType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Request type',
                      ),
                      items: [
                        for (final type in _RequestType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value != null) setState(() => _type = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    if (_type == _RequestType.bug) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _section,
                        decoration: const InputDecoration(
                          labelText: 'Section (optional)',
                        ),
                        items: [
                          for (final section in [
                            'Deck',
                            'Engine',
                            'Admin',
                            'Other',
                          ])
                            DropdownMenuItem(
                              value: section,
                              child: Text(section),
                            ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) => setState(() => _section = value),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _message,
                      enabled: !_busy,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: _type == _RequestType.bug
                            ? 'What were you doing, and what happened?'
                            : 'How can we help?',
                      ),
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 3000,
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Enter a message.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Reply email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 254,
                      validator: (value) {
                        final email = (value ?? '').trim();
                        return email.isEmpty ||
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(email)
                            ? null
                            : 'Enter a valid email address.';
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _send(outbox),
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        outbox.feedbackConfigured ? 'Send' : 'Save to outbox',
                      ),
                    ),
                    Text(
                      outbox.feedbackConfigured
                          ? 'Requests are sent when Vessel Assist is open and online.'
                          : 'Delivery is not configured. Requests stay on this device.',
                    ),
                    if (outbox.pendingFeedback > 0)
                      Text('Waiting to send: ${outbox.pendingFeedback}'),
                    if (outbox.rejectedFeedback.isNotEmpty)
                      ExpansionTile(
                        title: Text(
                          'Rejected requests: ${outbox.rejectedFeedback.length}',
                        ),
                        children: [
                          for (final message in outbox.rejectedFeedback)
                            ListTile(title: SelectableText(message)),
                        ],
                      ),
                    if (outbox.lastFeedbackSent != null)
                      const Text('Latest delivery: Sent'),
                  ],
                ),
              ),
            ),
    );
  }
}
