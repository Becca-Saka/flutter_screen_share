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
    // final texture = controller.textureHandler;
    final textureId = controller.textureId;
    print(textureId);
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
