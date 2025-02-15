import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:flutter_screen_share/src/source_selector.dart';

import 'display.dart';

class ScreenShareController {
  ValueNotifier<bool> isSharing = ValueNotifier(false);

  Stream<Uint8List>? frameStream;
  int? height;
  int? width;
  int? textureId;
  StreamSubscription<Uint8List>? _subscription;
  Future<void> setShowingPreview(bool value) async {
    await _getDisplaySize(null);
  }

  Future<void> _getDisplaySize(Display? source) async {
    // Gets displays first to know dimensions
    if (width == null || height == null) {
      if (source != null) {
        width = source.width;
        height = source.height;
      } else {
        final displays = await FlutterScreenShare.getDisplays();

        if (displays.isNotEmpty) {
          width = displays.first.width;
          height = displays.first.height;
        }
      }
    }
  }

  Future<void> startCaptureWithDialog({
    required BuildContext context,
    Function(Uint8List)? onData,
  }) async {
    final source = await showSourceSelectionDialog(context);
    if (source != null) {
      await startCapture(source: source, onData: onData);
    }
  }

  Future<void> startCapture({
    Display? source,
    Function(Uint8List)? onData,
  }) async {
    try {
      await _getDisplaySize(source);
      final result = await FlutterScreenShare.startCapture(source);
      isSharing.value = true;
      textureId = result['textureId'];

      isSharing.value = true;
      final stream = FlutterScreenShare.getStream();
      _subscription = stream.listen(
        (frame) {
          onData?.call(frame);
        },
        onError: (error) {
          debugPrint('Stream error: $error');
          release();
        },
        cancelOnError: false,
      );

      frameStream = stream;
    } catch (e) {
      debugPrint('Error starting screen share: $e');
    }
  }

  Future<void> stopCapture() async {
    await FlutterScreenShare.stopCapture();
    await release();
  }

  Future<void> release() async {
    _subscription?.cancel();
    setShowingPreview(false);
    frameStream = null;
    isSharing.value = false;
  }

  void dispose() {
    stopCapture();
  }
}
