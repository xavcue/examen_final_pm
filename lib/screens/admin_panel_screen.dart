import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/db_service.dart';
import '../models/user_model.dart';
import 'pick_location_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _desc = TextEditingController();

  double _lat = -2.9000;
  double _lng = -79.0000;

  bool _loading = false;
  String? _msg;

  String? _selectedUserUid;

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(initialLat: _lat, initialLng: _lng),
      ),
    );

    if (result != null && result is dynamic) {
      setState(() {
        _lat = result.latitude;
        _lng = result.longitude;
      });
    }
  }

  Future<void> _create() async {
    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      if (_desc.text.trim().isEmpty) {
        throw 'INGRESA UNA DESCRIPCION';
      }
      if (_selectedUserUid == null || _selectedUserUid!.isEmpty) {
        throw 'SELECCIONA UN USUARIO';
      }

      final db = DbService();
      final pid = await db.createPackage(
        description: _desc.text.trim(),
        userId: _selectedUserUid!,
        lat: _lat,
        lng: _lng,
      );

      setState(() {
        _msg = 'PAQUETE CREADO: $pid';
        _desc.clear();
      });
    } catch (e) {
      setState(() => _msg = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.role != 'ADMIN') {
      return const Scaffold(body: Center(child: Text('No autorizado')));
    }

    final db = DbService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CREAR PAQUETE',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _desc,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<UserModel>>(
                stream: db.streamUsersOnly(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'ERROR CARGANDO USUARIOS:\n${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snap.hasData) {
                    return const LinearProgressIndicator();
                  }

                  final users = snap.data!;
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'NO HAY USUARIOS USER REGISTRADOS',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  _selectedUserUid ??= users.first.uid;

                  return DropdownButtonFormField<String>(
                    value: _selectedUserUid,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar usuario (USER)',
                      border: OutlineInputBorder(),
                    ),
                    items: users.map((u) {
                      return DropdownMenuItem(
                        value: u.uid,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${u.name} (${u.email})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _loading
                        ? null
                        : (v) {
                            setState(() => _selectedUserUid = v);
                          },
                  );
                },
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Lat: ${_lat.toStringAsFixed(6)}'),
                    const SizedBox(height: 4),
                    Text('Lng: ${_lng.toStringAsFixed(6)}'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickLocation,
                      icon: const Icon(Icons.map),
                      label: const Text('Seleccionar en mapa'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_msg != null) Text(_msg!, textAlign: TextAlign.center),

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
