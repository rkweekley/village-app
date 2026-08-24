import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

/// Shows a modal as a bottom sheet on mobile phones and as a centered dialog
/// on desktop (web or native with wide viewport).
///
/// Parameters specific to bottom sheets (isScrollControlled, useSafeArea,
/// shape) are only applied on mobile. On desktop they are ignored.
Future<T?> showAdaptiveModalSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool useSafeArea = false,
  ShapeBorder? shape,
}) {
  final isDesktop = _isDesktopPlatform(context);

  if (isDesktop) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: builder(ctx),
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    shape: shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
    builder: builder,
  );
}

bool _isDesktopPlatform(BuildContext context) {
  // Native iPads should get a sheet, not a centered dialog (Apple HIG uses
  // sheets/popovers on iPad). Only true desktop platforms — and desktop-sized
  // web viewports — should get the centered Dialog treatment.
  if (!kIsWeb) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux =>
          true,
      _ => false,
    };
  }
  return MediaQuery.of(context).size.width >= 768;
}
