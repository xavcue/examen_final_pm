import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // NUEVO: PIN PARA ADMIN
  final _adminPin = TextEditingController();

  bool _loading = false;
  String? _error;

  // NUEVO: SELECTOR DE ROL
  String _selectedRole = 'USER';

  // CAMBIA ESTE PIN POR EL TUYO (NO LO PUBLIQUES)
  static const String ADMIN_SECRET_PIN = '1234';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _adminPin.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<SessionProvider>();

      final role = _selectedRole;

      // SI QUIERE SER ADMIN, VALIDAR PIN
      if (role == 'ADMIN') {
        final pin = _adminPin.text.trim();
        if (pin.isEmpty) {
          throw 'INGRESA EL PIN DE ADMIN';
        }
        if (pin != ADMIN_SECRET_PIN) {
          throw 'PIN DE ADMIN INCORRECTO';
        }
      }

      await session.auth.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: role,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == 'ADMIN';

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            // NUEVO: SELECTOR DE ROL
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'USER', child: Text('USER')),
                DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
              ],
              onChanged: _loading
                  ? null
                  : (v) {
                      if (v == null) return;
                      setState(() => _selectedRole = v);
                    },
            ),

            const SizedBox(height: 12),

            // NUEVO: PIN SOLO SI ES ADMIN
            if (isAdmin)
              TextField(
                controller: _adminPin,
                decoration: const InputDecoration(
                  labelText: 'PIN de administrador',
                ),
                obscureText: true,
              ),

            const SizedBox(height: 16),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Registrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
