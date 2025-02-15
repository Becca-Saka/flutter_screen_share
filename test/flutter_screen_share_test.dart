import 'dart:typed_data';

import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:flutter_screen_share/flutter_screen_share_method_channel.dart';
import 'package:flutter_screen_share/flutter_screen_share_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterScreenSharePlatform
    with MockPlatformInterfaceMixin
    implements FlutterScreenSharePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Uint8List?> startScreenCapture() {
    // TODO: implement startScreenCapture
    throw UnimplementedError();
  }

  @override
  Future<void> stopScreenCapture() {
    // TODO: implement stopScreenCapture
    throw UnimplementedError();
  }
}

void main() {
  final FlutterScreenSharePlatform initialPlatform =
      FlutterScreenSharePlatform.instance;

  test('$MethodChannelFlutterScreenShare is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterScreenShare>());
  });

  test('getPlatformVersion', () async {
    FlutterScreenShare flutterScreenSharePlugin = FlutterScreenShare();
    MockFlutterScreenSharePlatform fakePlatform =
        MockFlutterScreenSharePlatform();
    FlutterScreenSharePlatform.instance = fakePlatform;

    expect(await flutterScreenSharePlugin.getPlatformVersion(), '42');
  });
}
