import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';

void main() {
  runApp(const MaterialApp(home: ScreenCapture()));
}

class ScreenCapture extends StatefulWidget {
  const ScreenCapture({super.key});

  @override
  State<ScreenCapture> createState() => _ScreenCaptureState();
}

class _ScreenCaptureState extends State<ScreenCapture> {
  ScreenShareController screenSharer = ScreenShareController();

  void startCapture() async {
    await screenSharer.startCaptureWithDialog(
      context: context,
      onData: (Uint8List frame) {
        print('Frame received: ${frame.length} bytes');
      },
    );
    setState(() {});
  }

  void stopCapture() async {
    await screenSharer.stopCapture();

    setState(() {});
  }

  @override
  void dispose() {
    screenSharer.stopCapture();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: screenSharer.isSharing,
      builder: (context, isSharing, child) {
        return Column(
          children: [
            if (isSharing)
              Expanded(
                child: Center(child: ScreenShareView(controller: screenSharer)),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: !isSharing ? startCapture : stopCapture,
                child: Text(!isSharing ? 'Start Capture' : 'Stop Capture'),
              ),
            ),
          ],
        );
      },
    );
  }
}
