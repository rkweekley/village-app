import 'package:flutter/material.dart';
import 'package:village_app/core/theme/village_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VillageTheme.surfaceBase,
      body: Center(
        child: CircularProgressIndicator(color: context.palette.primary),
      ),
    );
  }
}
