import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/auth_gate.dart';

class UrjaApp extends StatelessWidget {
  const UrjaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'URJA',
    debugShowCheckedModeBanner: false,
    theme: UrjaTheme.light,
    home: const AuthGate(),
  );
}
