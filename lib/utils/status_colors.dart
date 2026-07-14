import 'package:flutter/material.dart';

/// Semantic status colours, per DESIGN.md §Status ("The Colour-Means-Something
/// Rule"). These are the committed status hues that live outside the teal seed
/// because they must read the same across light surfaces regardless of theme.
///
/// Failure/destructive emphasis is intentionally NOT here — it uses the
/// Material 3 `error` role (`Theme.of(context).colorScheme.error`) so it tracks
/// the theme.
class StatusColors {
  const StatusColors._();

  /// Pass / present / completed / token-present.
  static const Color success = Color(0xFF16A34A);

  /// Warning / partial / pending.
  static const Color warning = Color(0xFFD97706);
}
