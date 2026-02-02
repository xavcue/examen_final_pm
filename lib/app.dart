import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/session_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class TrackingApp extends StatelessWidget {
  const TrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider()..init(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tracking App',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: Consumer<SessionProvider>(
          builder: (context, session, _) {
            if (session.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return session.user == null
                ? const LoginScreen()
                : const HomeScreen();
          },
        ),
      ),
    );
  }
}
