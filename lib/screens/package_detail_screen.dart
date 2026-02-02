import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/db_service.dart';
import '../models/package_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class PackageDetailScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final DbService _db = DbService();
  final TextEditingController _msg = TextEditingController();
  GoogleMapController? _map;
  Timer? _simTimer;

  LatLng? _lastPos;

  @override
  void dispose() {
    _msg.dispose();
    _simTimer?.cancel();
    super.dispose();
  }

  void _moveCameraIfNeeded(LatLng pos) {
    if (_map == null) return;

    final changed =
        _lastPos == null ||
        (_lastPos!.latitude != pos.latitude ||
            _lastPos!.longitude != pos.longitude);

    if (!changed) return;

    _lastPos = pos;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_map == null) return;
      _map!.animateCamera(CameraUpdate.newLatLng(pos));
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Paquete')),
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<PackageModel?>(
        stream: _db.streamPackageById(widget.packageId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ERROR AL CARGAR PAQUETE:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pkg = snap.data;
          if (pkg == null) {
            return const Center(child: Text('Paquete no existe'));
          }

          final pos = LatLng(pkg.lat, pkg.lng);
          _moveCameraIfNeeded(pos);

          final markers = {
            Marker(markerId: const MarkerId('pkg'), position: pos),
          };

          return SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 240,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: pos,
                          zoom: 15,
                        ),
                        markers: markers,
                        onMapCreated: (c) {
                          _map = c;
                          _lastPos = pos;
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lat: ${pkg.lat.toStringAsFixed(6)}\nLng: ${pkg.lng.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pkg.description,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(label: Text(pkg.status)),
                    ],
                  ),
                ),

                if (session.role == 'ADMIN') _adminControlsCompact(pkg),

                const Divider(height: 1),

                Expanded(child: _chat(session, pkg.id)),

                Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: _chatInput(session, pkg.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _adminControlsCompact(PackageModel pkg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Estado:'),
          DropdownButton<String>(
            value: pkg.status,
            items: const [
              DropdownMenuItem(value: 'CREADO', child: Text('CREADO')),
              DropdownMenuItem(value: 'EN_CAMINO', child: Text('EN_CAMINO')),
              DropdownMenuItem(value: 'ENTREGADO', child: Text('ENTREGADO')),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await _db.updateStatus(pkg.id, v);
            },
          ),
          ElevatedButton.icon(
            onPressed: () {
              _simTimer?.cancel();
              _simTimer = _db.startSimulation(
                packageId: pkg.id,
                initialLat: pkg.lat,
                initialLng: pkg.lng,
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Simular'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _simTimer?.cancel();
            },
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  Widget _chat(SessionProvider session, String packageId) {
    return StreamBuilder<List<MessageModel>>(
      stream: _db.streamMessages(packageId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ERROR EN CHAT:\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final msgs = snap.data!;
        if (msgs.isEmpty) {
          return const Center(child: Text('Sin mensajes'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: msgs.length,
          itemBuilder: (context, i) {
            final m = msgs[i];
            final mine = m.senderUid == session.user!.uid;
            final time = DateFormat(
              'HH:mm',
            ).format(DateTime.fromMillisecondsSinceEpoch(m.timestamp));

            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mine
                      ? Colors.indigo.withOpacity(0.12)
                      : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: mine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(m.content),
                    const SizedBox(height: 4),
                    Text(
                      '${m.senderRole} • $time',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _chatInput(SessionProvider session, String packageId) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _msg,
            textInputAction: TextInputAction.send,
            decoration: const InputDecoration(
              hintText: 'Escribe un mensaje...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) async {
              await _send(session, packageId);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await _send(session, packageId);
          },
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }

  Future<void> _send(SessionProvider session, String packageId) async {
    final text = _msg.text.trim();
    if (text.isEmpty) return;
    _msg.clear();

    await _db.sendMessage(
      packageId: packageId,
      senderUid: session.user!.uid,
      senderRole: session.role,
      content: text,
    );
  }
}
