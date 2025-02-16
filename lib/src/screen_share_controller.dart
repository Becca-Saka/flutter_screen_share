import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:flutter_screen_share/src/source_selector.dart';

class ScreenShareController {
  ValueNotifier<bool> isSharing = ValueNotifier(false);

  int? height;
  int? width;
  int? textureId;
  StreamSubscription<Uint8List>? _subscription;

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
    Widget Function(List<Display>)? builder,
    EncodingOptions? options,
  }) async {
    final source = await showSourceSelectionDialog(context, builder: builder);
    if (source != null) {
      await startCapture(source: source, onData: onData, options: options);
    }
  }

  Future<void> startCapture({
    Display? source,
    EncodingOptions? options,
    Function(Uint8List)? onData,
  }) async {
    try {
      await _getDisplaySize(source);
      final result = await FlutterScreenShare.startCapture(source, options);
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
          _release();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error starting screen share: $e');
    }
  }

  Future<void> stopCapture() async {
    await FlutterScreenShare.stopCapture();
    await _release();
  }

  Future<void> _release() async {
    _subscription?.cancel();
    isSharing.value = false;
  }
}
