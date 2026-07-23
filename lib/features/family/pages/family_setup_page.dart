import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilySetupPage extends ConsumerWidget {
  const FamilySetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Setup')),
      body: const Center(
        child: Text('Family setup — coming in family sprint'),
      ),
    );
  }
}
