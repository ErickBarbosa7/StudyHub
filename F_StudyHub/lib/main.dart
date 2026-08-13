import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'ui/screens/create_room_screen.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: StudyHubApp()));
}

class StudyHubApp extends StatelessWidget {
  const StudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyHub',
      theme: buildTheme(),
      home: const HomeScreen(),
      routes: {
        CreateRoomScreen.routeName: (_) => const CreateRoomScreen(),
      },
    );
  }
}