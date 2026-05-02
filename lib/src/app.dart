import 'package:flutter/material.dart';

import 'movie_shell.dart';
import 'theme.dart';

class CineBookApp extends StatelessWidget {
  const CineBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CineBook',
      theme: buildCineBookTheme(),
      home: const MovieShell(),
    );
  }
}
