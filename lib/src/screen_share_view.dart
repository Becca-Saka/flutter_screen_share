import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';
import 'package:texture_rgba_renderer/texture_rgba_renderer.dart';

class ScreenShareView extends StatefulWidget {
  final ScreenShareController controller;
  const ScreenShareView({super.key, required this.controller});

  @override
  State<ScreenShareView> createState() => _ScreenShareViewState();
}

class _ScreenShareViewState extends State<ScreenShareView> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await widget.controller.setShowingPreview(true);
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final texture = controller.textureHandler;
    final textureId = texture.textureId;

    if (textureId == -1) {
      return const SizedBox.shrink();
    }

    final double videoWidth = controller.width?.toDouble() ?? 0;
    final double videoHeight = controller.height?.toDouble() ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;
        double maxHeight = constraints.maxHeight;

        double aspectRatio = videoWidth / videoHeight;
        double containerAspectRatio = maxWidth / maxHeight;

        double displayWidth, displayHeight;

        if (containerAspectRatio > aspectRatio) {
          // If the container is wider than the video, match height
          displayHeight = maxHeight;
          displayWidth = displayHeight * aspectRatio;
        } else {
          // If the container is taller than the video, match width
          displayWidth = maxWidth;
          displayHeight = displayWidth / aspectRatio;
        }

        return Container(
          color: Colors.grey[900], // Dark gray background
          alignment: Alignment.center,
          child: SizedBox(
            width: displayWidth,
            height: displayHeight,
            child: Texture(textureId: textureId),
          ),
        );
      },
    );
  }
}

class TextureHandler {
  final _textureRgbaRendererPlugin = TextureRgbaRenderer();

  int textureId = -1;

  int texturePtr = 0;
  final strideAlign = Platform.isMacOS ? 64 : 1;
  final pixelFormat =
      Platform.isMacOS ? ui.PixelFormat.bgra8888 : ui.PixelFormat.rgba8888;
  bool initialized = false;
  Future<void> initialize() async {
    await _createTexture();
    initialized = true;
  }

  Future<void> _createTexture() async {
    if (textureId != -1) return;
    await _textureRgbaRendererPlugin.closeTexture(0);
    final id = await _textureRgbaRendererPlugin.createTexture(0);

    if (id != -1) {
      debugPrint("Texture register success, textureId=$id");
      final ptr = await _textureRgbaRendererPlugin.getTexturePtr(0);
      debugPrint("texture ptr: ${ptr.toRadixString(16)}");

      textureId = id;
      texturePtr = ptr;
    }
  }

  void renderFrame(Uint8List frame, int? width, int? height) async {
    if (width == null || height == null) return;
    try {
      final stride = width * 4;

      // final stride = (width * 4 + (strideAlign - 1)) & ~(strideAlign - 1);

      await _textureRgbaRendererPlugin.onRgba(0, frame, height, width, stride);
    } catch (e, stackTrace) {
      debugPrint('Error processing frame: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void dispose() {
    if (textureId != -1) {
      _textureRgbaRendererPlugin.closeTexture(0);
    }
  }
}
