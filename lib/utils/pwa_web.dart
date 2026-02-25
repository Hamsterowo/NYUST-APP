// Web implementation using javascript interop
import 'dart:js_interop';

@JS('isPwaInstallDismissed')
external JSBoolean _isPwaInstallDismissed();
bool isPwaInstallDismissed() => _isPwaInstallDismissed().toDart;

@JS('isIos')
external JSBoolean _isIos();
bool isIos() => _isIos().toDart;

@JS('isPwaPromptAvailable')
external JSBoolean _isPwaPromptAvailable();
bool isPwaPromptAvailable() => _isPwaPromptAvailable().toDart;

@JS('setPwaInstallDismissed')
external void setPwaInstallDismissed();

@JS('showPwaInstallPrompt')
external JSBoolean _showPwaInstallPrompt();
bool showPwaInstallPrompt() => _showPwaInstallPrompt().toDart;
