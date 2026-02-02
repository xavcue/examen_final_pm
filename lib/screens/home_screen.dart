import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/db_service.dart';
import '../models/package_model.dart';
import 'package_detail_screen.dart';
import 'admin_panel_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final db = DbService();

    final stream = (session.role == 'ADMIN')
        ? db.streamAllPackages()
        : db.streamUserPackages(session.user!.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text('Paquetes (${session.role})'),
        actions: [
          if (session.role == 'ADMIN')
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
            ),
          IconButton(
            onPressed: () async {
              await session.auth.logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<PackageModel>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ERROR AL LEER PAQUETES:\n${snap.error}\n\nREVISA RULES /packages',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No hay paquetes'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = items[i];
              return ListTile(
                title: Text(p.description),
                subtitle: Text('Estado: ${p.status}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PackageDetailScreen(packageId: p.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
