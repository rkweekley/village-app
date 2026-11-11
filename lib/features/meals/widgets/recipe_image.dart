import 'package:flutter/material.dart';
import 'package:village_app/core/theme/village_theme.dart';

/// Recipe photo rendered from a network URL.
///
/// This exists because the recipe screens had three separate image problems:
///
///  * every tile downloaded and decoded the **full-resolution original** and
///    there was no `cacheWidth`, so a scrolling grid retained large bitmaps
///    (#107);
///  * a tile showed **nothing at all** while loading — a blank card region —
///    because no `loadingBuilder` was supplied (#107);
///  * failures were swallowed into one generic icon with no logging and no
///    retry, so "no photo" and "image host is down" looked identical (#108).
///
/// Rendering rules:
///  * empty/missing URL  → static "No photo" state;
///  * while decoding     → same-size skeleton, never a blank hole;
///  * load failure       → logged URL + tap-to-retry over the placeholder.
class RecipeImage extends StatefulWidget {
  const RecipeImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth = 400,
    this.iconSize = 28,
    this.borderRadius,
    this.showRetryLabel = false,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Decode width in device pixels. Keep it close to the rendered size — the
  /// point is to avoid decoding a 1000px original into a 160px tile.
  final int cacheWidth;

  final double iconSize;
  final BorderRadius? borderRadius;

  /// Show a small "Tap to retry" hint under the icon (used on large surfaces
  /// such as the detail hero, hidden on small tiles where there is no room).
  final bool showRetryLabel;

  @override
  State<RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<RecipeImage> {
  int _attempt = 0;

  Future<void> _retry() async {
    // Drop the failed entry from the in-memory image cache, otherwise the same
    // URL resolves to the cached failure again and the retry is a no-op.
    await NetworkImage(widget.url!.trim()).evict();
    if (mounted) setState(() => _attempt++);
  }

  @override
  Widget build(BuildContext context) {
    final url = (widget.url ?? '').trim();

    Widget child;
    if (url.isEmpty) {
      child = _stateBox(
        context,
        icon: Icons.restaurant_menu_rounded,
        label: 'No photo',
      );
    } else {
      child = Image.network(
        url,
        key: ValueKey('$url#$_attempt'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        loadingBuilder: (ctx, image, progress) =>
            progress == null ? image : _skeleton(context),
        errorBuilder: (ctx, error, stack) {
          debugPrint('[RecipeImage] failed: $url — $error');
          return _failureBox(context);
        },
      );
    }

    final radius = widget.borderRadius;
    return radius == null
        ? child
        : ClipRRect(borderRadius: radius, child: child);
  }

  Widget _skeleton(BuildContext context) => Container(
    width: widget.width,
    height: widget.height,
    color: context.palette.textTertiary.withValues(alpha: 0.10),
    child: Center(
      child: SizedBox(
        width: widget.iconSize,
        height: widget.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.palette.textTertiary,
        ),
      ),
    ),
  );

  Widget _stateBox(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) => Container(
    width: widget.width,
    height: widget.height,
    color: context.palette.primary.withValues(alpha: 0.10),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: widget.iconSize, color: context.palette.primary),
          if (widget.showRetryLabel) ...[
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _failureBox(BuildContext context) => Semantics(
    button: true,
    label: 'Recipe photo failed to load. Tap to retry.',
    child: GestureDetector(
      onTap: _retry,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: context.palette.primary.withValues(alpha: 0.10),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                size: widget.iconSize,
                color: context.palette.primary,
              ),
              if (widget.showRetryLabel) ...[
                const SizedBox(height: 4),
                Text(
                  'Tap to retry',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
