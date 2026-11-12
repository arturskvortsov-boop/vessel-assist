import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

Future<XFile?> takeBrowserPhoto(BuildContext context) {
  return showDialog<XFile>(
    context: context,
    builder: (_) => const _BrowserCameraDialog(),
  );
}

class _BrowserCameraDialog extends StatefulWidget {
  const _BrowserCameraDialog();

  @override
  State<_BrowserCameraDialog> createState() => _BrowserCameraDialogState();
}

class _BrowserCameraDialogState extends State<_BrowserCameraDialog> {
  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  bool _ready = false;
  String? _error;

  Future<void> _start(web.HTMLVideoElement video) async {
    if (!mounted) return;
    _video = video;
    video
      ..autoplay = true
      ..muted = true
      ..playsInline = true;
    video.style
      ..objectFit = 'contain'
      ..backgroundColor = 'black'
      ..pointerEvents = 'none';
    video.oncanplay = ((web.Event event) {
      if (mounted) setState(() => _ready = true);
    }).toJS;

    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              audio: false.toJS,
              video: web.MediaTrackConstraints(
                facingMode: web.ConstrainDOMStringParameters(
                  ideal: 'environment'.toJS,
                ),
              ),
            ),
          )
          .toDart;
      if (!mounted) {
        _stop(stream);
        return;
      }
      _stream = stream;
      video.srcObject = stream;
      await video.play().toDart;
    } catch (_) {
      _releaseCamera();
      if (mounted) {
        setState(() {
          _ready = false;
          _error = 'Camera unavailable. Check that a camera is connected and allow camera access in the browser.';
        });
      }
    }
  }

  void _stop(web.MediaStream stream) {
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }
  }

  void _releaseCamera() {
    final stream = _stream;
    if (stream != null) _stop(stream);
    _stream = null;
    final video = _video;
    if (video != null) {
      video.oncanplay = null;
      video.srcObject = null;
    }
    _video = null;
  }

  void _capture() {
    final video = _video;
    if (video == null || video.videoWidth == 0 || video.videoHeight == 0) {
      return;
    }
    try {
      final scale = math.min(
        1.0,
        2400 / math.max(video.videoWidth, video.videoHeight),
      );
      final canvas = web.HTMLCanvasElement()
        ..width = (video.videoWidth * scale).round()
        ..height = (video.videoHeight * scale).round();
      canvas.context2D.drawImage(video, 0, 0, canvas.width, canvas.height);
      final data = canvas.toDataURL('image/jpeg', 0.95.toJS);
      final bytes = base64Decode(data.substring(data.indexOf(',') + 1));
      _releaseCamera();
      Navigator.of(context).pop(
        XFile.fromData(bytes, name: 'Camera photo.jpg', mimeType: 'image/jpeg'),
      );
    } catch (_) {
      setState(() => _error = 'Could not capture the photo.');
    }
  }

  @override
  void dispose() {
    _releaseCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Take photo'),
    content: SizedBox(
      width: 480,
      child: _error != null
          ? Text(_error!)
          : AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HtmlElementView.fromTagName(
                    tagName: 'video',
                    onElementCreated: (element) =>
                        _start(element as web.HTMLVideoElement),
                  ),
                  if (!_ready) const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          _releaseCamera();
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _ready && _error == null ? _capture : null,
        child: const Text('Capture'),
      ),
    ],
  );
}
