import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _notice = '''
Vessel Assist is a tool for preliminary calculations and planning. The app’s calculations and estimates may contain errors or inaccuracies.

Before relying on any result for navigation, cargo operations, or vessel records, independently verify the input data and results against approved vessel documents, official sources, and applicable onboard procedures.

To the extent permitted by applicable law, the developers of Vessel Assist disclaim liability for loss or damage arising from reliance on the app’s results. Any liability that cannot lawfully be excluded or limited remains in effect.''';

Future<void> showImportantNotice(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => _NoticeDialog(
    action: TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Close'),
    ),
  ),
);

class StartupNotice extends StatefulWidget {
  const StartupNotice({super.key, required this.child});

  final Widget child;

  @override
  State<StartupNotice> createState() => _StartupNoticeState();
}

class _StartupNoticeState extends State<StartupNotice> {
  static const _acknowledgmentKey = 'importantNoticeAcknowledged';
  final _settings = Hive.box('settings');
  late bool _acknowledged = _settings.get(_acknowledgmentKey) == true;
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _acknowledge() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await _settings.put(_acknowledgmentKey, true);
      if (mounted) setState(() => _acknowledged = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: !_acknowledged,
        child: ExcludeFocus(excluding: !_acknowledged, child: widget.child),
      ),
      if (!_acknowledged) ...[
        ModalBarrier(color: Theme.of(context).scaffoldBackgroundColor),
        SafeArea(
          child: _NoticeDialog(
            error: _saveFailed
                ? 'Could not save your acknowledgment. Try again.'
                : null,
            action: FilledButton(
              onPressed: _saving ? null : _acknowledge,
              child: Text(
                _saving ? 'Saving…' : 'I understand and wish to continue',
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class _NoticeDialog extends StatelessWidget {
  const _NoticeDialog({required this.action, this.error});

  final Widget action;
  final String? error;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Important Notice'),
    scrollable: true,
    content: SizedBox(
      width: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(_notice),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [action],
  );
}
