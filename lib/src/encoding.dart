enum EncodingType { webp, jpeg }

class EncodingOptions {
  final EncodingType type;
  final int fps;
  final double quality;

  const EncodingOptions({
    this.type = EncodingType.jpeg,
    this.fps = 24,
    this.quality = 0.8,
  });

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'fps': fps,
    'quality': quality,
  };
}
