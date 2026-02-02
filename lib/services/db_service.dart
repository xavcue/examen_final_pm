import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/package_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class DbService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  DatabaseReference packagesRef() => _db.child('packages');
  DatabaseReference messagesRef(String packageId) =>
      _db.child('messages').child(packageId);

  DatabaseReference usersRef() => _db.child('users');

  Stream<List<PackageModel>> streamAllPackages() {
    return packagesRef().onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <PackageModel>[];
      final map = Map<dynamic, dynamic>.from(data as Map);
      final list = <PackageModel>[];
      map.forEach((key, value) {
        list.add(
          PackageModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          ),
        );
      });
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Stream<List<PackageModel>> streamUserPackages(String uid) {
    return packagesRef().orderByChild('userId').equalTo(uid).onValue.map((
      event,
    ) {
      final data = event.snapshot.value;
      if (data == null) return <PackageModel>[];
      final map = Map<dynamic, dynamic>.from(data as Map);
      final list = <PackageModel>[];
      map.forEach((key, value) {
        list.add(
          PackageModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          ),
        );
      });
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<String> createPackage({
    required String description,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final newRef = packagesRef().push();
    await newRef.set({
      'description': description,
      'status': 'CREADO',
      'lat': lat,
      'lng': lng,
      'userId': userId,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    return newRef.key!;
  }

  Future<void> updateStatus(String packageId, String status) async {
    await packagesRef().child(packageId).update({
      'status': status,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateLocation(String packageId, double lat, double lng) async {
    await packagesRef().child(packageId).update({
      'lat': lat,
      'lng': lng,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Stream<PackageModel?> streamPackageById(String packageId) {
    return packagesRef().child(packageId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      return PackageModel.fromMap(
        packageId,
        Map<dynamic, dynamic>.from(data as Map),
      );
    });
  }

  Stream<List<MessageModel>> streamMessages(String packageId) {
    return messagesRef(packageId).orderByChild('timestamp').onValue.map((
      event,
    ) {
      final data = event.snapshot.value;
      if (data == null) return <MessageModel>[];
      final map = Map<dynamic, dynamic>.from(data as Map);
      final list = <MessageModel>[];
      map.forEach((key, value) {
        list.add(
          MessageModel.fromMap(
            key.toString(),
            Map<dynamic, dynamic>.from(value),
          ),
        );
      });
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  Future<void> sendMessage({
    required String packageId,
    required String senderUid,
    required String senderRole,
    required String content,
  }) async {
    final newRef = messagesRef(packageId).push();
    await newRef.set({
      'senderUid': senderUid,
      'senderRole': senderRole,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Timer? startSimulation({
    required String packageId,
    required double initialLat,
    required double initialLng,
  }) {
    double lat = initialLat;
    double lng = initialLng;

    final timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      lat = lat + 0.0003;
      lng = lng + 0.0003;
      await updateLocation(packageId, lat, lng);
    });

    return timer;
  }

  // =========================
  // USERS (PARA ADMIN PANEL)
  // =========================
  Stream<List<UserModel>> streamUsersOnly() {
    return usersRef().onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <UserModel>[];

      final map = Map<dynamic, dynamic>.from(data as Map);
      final list = <UserModel>[];

      map.forEach((key, value) {
        final user = UserModel.fromMap(
          key.toString(),
          Map<dynamic, dynamic>.from(value),
        );

        if (user.role == 'USER') {
          list.add(user);
        }
      });

      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }
}
