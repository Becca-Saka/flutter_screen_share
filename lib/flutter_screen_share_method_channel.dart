import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_screen_share_platform_interface.dart';
import 'src/display.dart';
import 'src/encording.dart';

/// An implementation of [FlutterScreenSharePlatform] that uses method channels.
class MethodChannelFlutterScreenShare extends FlutterScreenSharePlatform {
  static const MethodChannel _channel = MethodChannel('flutter_screen_share');
  static const EventChannel _eventChannel = EventChannel(
    'flutter_screen_share/stream',
  );
  static Stream<Uint8List>? _frameStream;

  /// Start screen capture and return a stream of frame data
  @override
  Future<Map> startCapture([Display? source, EncodingOptions? options]) async {
    final defaultOptions = const EncodingOptions();
    final Map<String, dynamic> arguments = {
      'source': source?.toMap(),
      'options': (options ?? defaultOptions).toMap(),
    };
    return await _channel.invokeMethod('startCapture', arguments);
  }

  @override
  Stream<Uint8List> getStream() {
    _frameStream ??= _eventChannel.receiveBroadcastStream().map((
      dynamic event,
    ) {
      return (event as Uint8List);
    });
    return _frameStream!;
  }

  /// Stop screen capture
  @override
  Future<void> stopCapture() async {
    await _channel.invokeMethod('stopCapture');
  }

  /// Get available displays
  @override
  Future<List<Display>> getDisplays() async {
    final List<dynamic> displays = await _channel.invokeMethod('getDisplays');
    return displays.map((display) => Display.fromMap(display)).toList();
  }

  @override
  Future<List<Display>> getSources() async {
    final sources = await _channel.invokeMethod('getSources');
    final sourcesList = List.from(sources);
    return sourcesList.map((source) => Display.fromMap(source)).toList();
  }
}
