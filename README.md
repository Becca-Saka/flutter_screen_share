
# Flutter Screen Share Plugin Documentation

This plugin allows you to capture and stream the screen content of a macOS device in your Flutter application.

## Basic Concepts

* **ScreenCaptureKit (SCKit):** This plugin utilizes Apple's ScreenCaptureKit API for high-performance screen recording capabilities.
* **texture_rgba_renderer:** This package is used to render the raw RGBA frame data onto a Flutter texture. This allows for efficient display of the captured screen content.

## Permissions

This plugin requires Screen Recording permissions on macOS. Users will be prompted to grant these permissions when the screen capture is first initiated.

To ensure your application has the necessary permissions, you must add the following key to your `entitlements.macOS` file:

```xml
<key>com.apple.security.screen-recording</key>
<true/>
```

**Important:** ScreenCaptureKit is available on macOS 12.3 and later. Ensure your deployment target is set accordingly.

## Installation

Add the plugin to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_screen_share: ^latest_version
```

Then, run `flutter pub get`.

## Usage

### 1. Import the Package

```dart
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
```

### 2. Create a `ScreenShareController`

```dart
ScreenShareController screenSharer = ScreenShareController();
```

### 3. Start Capture

* **`startCaptureWithDialog`:** Allows the user to select the source (display or window) to capture.
* **`startCapture`:** Starts screen capture with the default display if no source is passed, or with the source passed.

```dart
void startCapture() async {
    await screenSharer.startCaptureWithDialog(
      context: context,
      onData: (Uint8List frame) {
        // Handle the frame data here
      },
    );
    setState(() {});
}
```

or

```dart
void startCaptureWithSource(Display? source) async {
    await screenSharer.startCapture(
      source: source,
      onData: (Uint8List frame) {
        // Handle the frame data here
      },
    );
    setState(() {});
}
```

* **`onData`:** A callback function that receives the captured frame data as a `Uint8List`.
* **`source`:** A `Display` object representing either a display or a window. If null, the default display is used.

### 4. Stop Capture

```dart
void stopCapture() async {
  await screenSharer.stopCapture();
  setState(() {});
}
```

### 5. Display the Captured Content

Use the `ScreenShareView` widget to display the captured content.

```dart
ValueListenableBuilder(
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
    }
);
```

### 6. Dispose the Controller

```dart
@override
void dispose() {
  screenSharer.dispose();
  super.dispose();
}
```

### 7. Get Available Displays

```dart
Future<void> getAvailableDisplays() async {
  final displays = await FlutterScreenShare.getDisplays();
  for (var display in displays) {
    print('Display ID: ${display.id}, Width: ${display.width}, Height: ${display.height}');
  }
}
```

### 8. Get Available Sources (Displays and Windows)

```dart
Future<void> getAvailableSources() async {
  final sources = await FlutterScreenShare.getSources();
  for (var source in sources) {
      if(source.type == display){
          print('Display ID: ${source.id}, Width: ${source.width}, Height: ${source.height}');
      }else if(source.type == window){
          print('Window ID: ${source.id}, Name: ${source.name}, Owner: ${source.owner}');
      }
  }
}
```

### Available Methods

* **`ScreenShareController.startCaptureWithDialog(BuildContext context, Function(Uint8List)? onData)`:** Starts screen capture with a dialog to select the source.
* **`ScreenShareController.startCapture(Display? source, Function(Uint8List)? onData)`:** Starts screen capture with a specific source, or the default display if the source is null.
* **`ScreenShareController.stopCapture()`:** Stops screen capture.
* **`ScreenShareController.dispose()`:** Disposes the controller and releases resources.
* **`ScreenShareController.setShowingPreview(bool value)`:** Enables or disables previewing the captured screen.
* **`ScreenShareView(ScreenShareController controller)`:** A widget to display the captured screen content.

## Example Usage

See the provided example code for a complete implementation. Remember to handle potential errors and exceptions appropriately in your application.
