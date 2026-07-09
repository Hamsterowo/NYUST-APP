import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// Shows a password dialog that re-authenticates against the app endpoint
/// (`/Token`). Used for two distinct flows, differentiated by the parameters:
///
///  * **Expired-token / on-demand** (default): a feature's token expired with no
///    saved credential — [title]/[message] default to the "re-authentication
///    required" copy and an opt-in "remember password" checkbox is shown.
///  * **Enable remember-password**: opened from the credential settings page to
///    turn remembering on — pass a title/message describing that intent and
///    [showRememberOption] = false with [remember] = true, so there's no
///    confusing extra checkbox (remembering is already the whole point).
///
/// Returns `true` when the user successfully re-authenticated (a fresh token was
/// minted), `false`/`null` when cancelled.
Future<bool?> showAppApiPasswordDialog(
  BuildContext context,
  WidgetRef ref, {
  String? title,
  String? message,
  bool showRememberOption = true,
  bool remember = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _AppApiPasswordDialog(
      ref: ref,
      title: title,
      message: message,
      showRememberOption: showRememberOption,
      initialRemember: remember,
    ),
  );
}

class _AppApiPasswordDialog extends StatefulWidget {
  final WidgetRef ref;
  final String? title;
  final String? message;
  final bool showRememberOption;
  final bool initialRemember;
  const _AppApiPasswordDialog({
    required this.ref,
    this.title,
    this.message,
    this.showRememberOption = true,
    this.initialRemember = false,
  });

  @override
  State<_AppApiPasswordDialog> createState() => _AppApiPasswordDialogState();
}

class _AppApiPasswordDialogState extends State<_AppApiPasswordDialog> {
  final _controller = TextEditingController();
  late bool _remember = widget.initialRemember;
  bool _submitting = false;
  bool _error = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text;
    if (password.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = false;
    });
    final ok = await widget.ref
        .read(authProvider)
        .api
        .appApi
        .reloginWithPassword(password, remember: _remember);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title ?? l.appAuthRequiredTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message ?? l.appAuthRequiredMessage),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            enabled: !_submitting,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l.loginPasswordLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              errorText: _error ? l.loginFailed : null,
            ),
          ),
          if (widget.showRememberOption) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _remember,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _remember = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l.loginRememberPassword),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l.appAuthCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.appAuthUnlock),
        ),
      ],
    );
  }
}
