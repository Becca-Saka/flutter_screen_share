class Display {
  final int id;
  final int? width;
  final int? height;
  final String? name;
  final String? type;
  final String? owner;

  Display({
    required this.id,
    required this.name,

    this.width,
    this.height,
    this.type,
    this.owner,
  });

  factory Display.fromMap(Map<dynamic, dynamic> map) {
    return Display(
      id: map['id'] as int,
      width: map['width'] as int?,
      height: map['height'] as int?,
      name: map['name'] as String?,
      type: map['type'] as String?,
      owner: map['owner'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'width': width,
      'height': height,
      'name': name,
      'type': type,
      'owner': owner,
    };
  }
}
