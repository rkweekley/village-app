import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:village_app/core/theme/village_theme.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App icon + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.palette.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                const Text('Village',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Version 1.0.0',
                    style: TextStyle(fontSize: 14, color: context.palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Text(
            'Village helps families stay organized — chores, meals, shopping lists, rewards, and more, all in one place.',
            style: TextStyle(fontSize: 14, color: context.palette.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Legal links
          _linkTile(context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => launchUrl(
                Uri.parse('https://villagefamily.app/privacy')),
          ),
          _linkTile(context,
            icon: Icons.mail_outline,
            title: 'Contact Support',
            onTap: () => launchUrl(
                Uri.parse('mailto:support@villagefamily.app')),
          ),
          _linkTile(context,
            icon: Icons.info_outline,
            title: 'Recipe data provided by TheMealDB',
            subtitle: 'A free, community-maintained recipe database',
            onTap: () =>
                launchUrl(Uri.parse('https://www.themealdb.com')),
          ),

          const SizedBox(height: 32),
          Text('© 2026 Village. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.palette.textTertiary)),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: VillageTheme.surfaceCard,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: context.palette.primary),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: Icon(Icons.chevron_right_rounded,
            color: context.palette.textTertiary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
