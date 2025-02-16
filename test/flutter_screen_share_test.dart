import 'package:flutter/services.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:flutter_screen_share/src/display.dart';
import 'package:flutter_screen_share/src/encording.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterScreenShare', () {
    const channel = MethodChannel('flutter_screen_share');

    final List<MethodCall> log = <MethodCall>[];
    dynamic returnData;

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            return returnData;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getDisplays returns list of Display objects', () async {
      returnData = [
        {
          'type': 'display',
          'id': 1,
          'width': 1920,
          'height': 1080,
          'name': 'Display 1',
        },
      ];

      final displays = await FlutterScreenShare.getDisplays();

      expect(log, hasLength(1));
      expect(log.first.method, 'getDisplays');
      expect(displays, isA<List<Display>>());

      final display = displays.first;
      expect(display.id, 1);
      expect(display.width, 1920);
      expect(display.height, 1080);
      expect(display.name, 'Display 1');
      expect(display.type, 'display');
    });

    test('getSources returns list of Display objects', () async {
      returnData = [
        {
          'type': 'display',
          'id': 1,
          'width': 1920,
          'height': 1080,
          'name': 'Display 1',
        },
        {'type': 'window', 'id': 2, 'name': 'Window 1', 'owner': 'App 1'},
      ];

      final sources = await FlutterScreenShare.getSources();

      expect(log, hasLength(1));
      expect(log.first.method, 'getSources');
      expect(sources, isA<List<Display>>());
      expect(sources.length, 2);

      final display = sources.first;
      expect(display.type, 'display');
      expect(display.id, 1);
      expect(display.width, 1920);
      expect(display.height, 1080);

      final window = sources.last;
      expect(window.type, 'window');
      expect(window.id, 2);
      expect(window.name, 'Window 1');
      expect(window.owner, 'App 1');
    });

    test('startCapture with Display and EncodingOptions', () async {
      returnData = {'textureId': 123};

      final display = Display(
        id: 1,
        name: 'Display 1',
        width: 1920,
        height: 1080,
        type: 'display',
      );

      final options = EncodingOptions(
        type: EncodingType.webp,
        fps: 30,
        quality: 0.8,
      );

      await FlutterScreenShare.startCapture(display, options);

      expect(log, hasLength(1));
      expect(log.first.method, 'startCapture');
      expect(log.first.arguments, {
        'source': display.toMap(),
        'options': options.toMap(),
      });
    });

    test('EncodingOptions toMap converts correctly', () {
      final options = EncodingOptions(
        type: EncodingType.webp,
        fps: 30,
        quality: 0.8,
      );

      final map = options.toMap();
      expect(map['type'], 'webp');
      expect(map['fps'], 30);
      expect(map['quality'], 0.8);
    });

    test('Display fromMap creates correct object', () {
      final map = {
        'id': 1,
        'width': 1920,
        'height': 1080,
        'name': 'Display 1',
        'type': 'display',
        'owner': 'System',
      };

      final display = Display.fromMap(map);
      expect(display.id, 1);
      expect(display.width, 1920);
      expect(display.height, 1080);
      expect(display.name, 'Display 1');
      expect(display.type, 'display');
      expect(display.owner, 'System');
    });

    test('stopCapture stops screen capture', () async {
      returnData = null;
      await FlutterScreenShare.stopCapture();
      expect(log, hasLength(1));
      expect(log.first.method, 'stopCapture');
    });

    test('startCapture throws exception on invalid display', () async {
      returnData = PlatformException(
        code: 'NO_DISPLAY',
        message: 'Selected display not found',
      );

      final display = Display(id: 999, name: 'Invalid Display');

      expect(
        () => FlutterScreenShare.startCapture(display),
        throwsA(isA<PlatformException>()),
      );
    });

    test('Display toMap handles null values', () {
      final display = Display(id: 1, name: 'Test');
      final map = display.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test');
      expect(map['width'], null);
      expect(map['height'], null);
      expect(map['type'], null);
      expect(map['owner'], null);
    });
  });
}
