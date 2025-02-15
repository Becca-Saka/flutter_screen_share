import 'dart:typed_data';

import 'flutter_screen_share_platform_interface.dart';
import 'src/display.dart';

export 'src/screen_share_controller.dart';
export 'src/screen_share_view.dart';

class FlutterScreenShare {
  static Future<Stream<Uint8List>> startCapture(Display? source) {
    return FlutterScreenSharePlatform.instance.startCapture(source);
  }

  static Future<void> stopCapture() {
    return FlutterScreenSharePlatform.instance.stopCapture();
  }

  static Future<List<Display>> getDisplays() {
    return FlutterScreenSharePlatform.instance.getDisplays();
  }

  static Future<List<Display>> _getSources() {
    return FlutterScreenSharePlatform.instance.getSources();
  }

  static Future<List<Display>> getAllSources() {
    return _getSources();
  }

  static Future<List<Display>> getSources() async {
    final sources = await _getSources();
    final excludeOwners = [
      'Window Server',
      'Dock',
      'Wallpaper',
      'Control Centre',
      'Unknown App',
    ];
    final excludeName = ['Unknown App', 'Item-0'];
    final filtered =
        sources
            .where(
              (source) =>
                  source.name != null &&
                  source.name!.isNotEmpty &&
                  !excludeOwners.contains(source.owner) &&
                  !excludeName.contains(source.name) &&
                  source.name != 'Unknown App',
            )
            .toList();
    return filtered;
  }
}
