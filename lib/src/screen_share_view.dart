import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';

class ScreenShareView extends StatefulWidget {
  final ScreenShareController controller;
  const ScreenShareView({super.key, required this.controller});

  @override
  State<ScreenShareView> createState() => _ScreenShareViewState();
}

class _ScreenShareViewState extends State<ScreenShareView> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final textureId = controller.textureId;

    if (textureId == null || textureId == -1) {
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
          displayHeight = maxHeight;
          displayWidth = displayHeight * aspectRatio;
        } else {
          displayWidth = maxWidth;
          displayHeight = displayWidth / aspectRatio;
        }

        return Container(
          color: Colors.grey[900],
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
