// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screen_share/flutter_screen_share.dart';

/// Displays a custom dialog with a list of shareable sources.
/// Returns the selected source [Display] or null if the user cancels.
Future<Display?> showSourceSelectionDialog(
  BuildContext context, {
  Widget Function(List<Display>)? builder,
}) async {
  // Get the list of available sources from the native side.
  final sources = await FlutterScreenShare.getSources();

  return showDialog<Display>(
    context: context,
    builder: (context) {
      if (builder != null) {
        return builder(sources);
      }
      return AlertDialog(
        title: const Text('Select a Source'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];

              final type = source.type;
              final owner = source.owner;

              String name = source.name ?? '';
              if (type == 'window') {
                name = 'Window - $owner - $name';
              }
              return ListTile(
                title: Text(name),

                onTap: () {
                  Navigator.of(context).pop(source);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
