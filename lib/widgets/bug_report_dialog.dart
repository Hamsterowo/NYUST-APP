import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/top_snack_bar.dart';

class BugReportDialog extends StatefulWidget {
  const BugReportDialog({super.key});

  @override
  State<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends State<BugReportDialog> {
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  XFile? _selectedImage;
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).reportImagePickError(e.toString()),
          type: SnackBarType.error,
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<String> _getDeviceInfo() async {
    String appVersion = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      appVersion = 'unknown';
    }

    if (kIsWeb) {
      return 'Web Browser (App v$appVersion)';
    }
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion} (App v$appVersion)';
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      showTopSnackBar(
        context,
        AppLocalizations.of(context).reportEmptyDescriptionWarning,
        type: SnackBarType.warning,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final deviceInfo = await _getDeviceInfo();
      
      final result = await auth.api.submitBugReport(
        description: description,
        contact: _contactController.text.trim(),
        deviceInfo: deviceInfo,
        imageFile: _selectedImage,
      );

      if (mounted) {
        if (result['status'] == 'success') {
          Navigator.pop(context); // Close report dialog
          
          final caseId = result['caseId'] ?? 'unknown';
          _showSuccessDialog(caseId);
        } else {
          final l10n = AppLocalizations.of(context);
          String errorMessage;
          switch (result['code']) {
            case 'timeout':
              errorMessage = l10n.errorTimeout;
              break;
            case 'connection_error':
              errorMessage = l10n.errorConnection;
              break;
            case 'server_error':
              errorMessage = '${l10n.errorServer} (${result['statusCode']})';
              break;
            case 'format_error':
              errorMessage = l10n.errorFormat;
              break;
            case 'api_failed':
              errorMessage = l10n.errorApiCallFailed(result['error'] ?? '');
              break;
            default:
              errorMessage = result['message'] ?? l10n.reportSubmitError;
              break;
          }
          showTopSnackBar(
            context,
            errorMessage,
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          context,
          AppLocalizations.of(context).reportSendError(e.toString()),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String caseId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.teal, size: 28),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).reportIssueTitle),
          ],
        ),
        content: Text(
          AppLocalizations.of(ctx).reportSubmitSuccess(caseId),
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).confirm),
          ),
        ],
      ),
    );
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@hamster.tw'));
    showTopSnackBar(
      context,
      AppLocalizations.of(context).reportCopiedEmail,
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reportIssueTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description TextField
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.reportDescriptionPrompt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Info TextField
              TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  hintText: l10n.reportContactPrompt,
                  prefixIcon: const Icon(Icons.contact_mail_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker Area
              if (_selectedImage == null)
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.reportAddImage),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImage!.path,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImage!.path),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: _removeImage,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Email support section
              InkWell(
                onTap: _copyEmail,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: colorScheme.outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.reportEmailOrContactUs('support@hamster.tw'),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.outline,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.reportSend),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
