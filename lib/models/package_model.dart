class PackageModel {
  final String id;
  final String description;
  final String status;
  final double lat;
  final double lng;
  final String userId;
  final int updatedAt;

  PackageModel({
    required this.id,
    required this.description,
    required this.status,
    required this.lat,
    required this.lng,
    required this.userId,
    required this.updatedAt,
  });

  factory PackageModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return PackageModel(
      id: id,
      description: (map['description'] ?? '').toString(),
      status: (map['status'] ?? 'CREADO').toString(),
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      userId: (map['userId'] ?? '').toString(),
      updatedAt: (map['updatedAt'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'status': status,
      'lat': lat,
      'lng': lng,
      'userId': userId,
      'updatedAt': updatedAt,
    };
  }
}
