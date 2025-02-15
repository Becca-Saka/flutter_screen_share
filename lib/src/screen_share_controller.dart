import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:flutter_screen_share/src/source_selector.dart';

import 'display.dart';

class ScreenShareController {
  TextureHandler textureHandler = TextureHandler();
  bool showingPreview = false;
  ValueNotifier<bool> isSharing = ValueNotifier(false);
  // bool isSharing = false;
  Stream<Uint8List>? frameStream;
  int? height;
  int? width;
  StreamSubscription<Uint8List>? _subscription;
  Future<void> setShowingPreview(bool value) async {
    showingPreview = value;
    if (value && !textureHandler.initialized) {
      await _getDisplaySize(null);
      textureHandler.initialize();
    }
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
      final stream = await FlutterScreenShare.startCapture(source);
      isSharing.value = true;
      _subscription = stream.listen(
        (frame) {
          onData?.call(frame);
          if (showingPreview) {
            textureHandler.renderFrame(frame, width, height);
          }
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
    textureHandler.dispose();
  }
}
