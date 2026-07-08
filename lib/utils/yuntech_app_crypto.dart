import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Client-side crypto that mirrors the official 行動雲科 app, so the
/// app-endpoint login (`MobileAppService/Token`) is accepted by the server.
///
/// Reverse-engineered from the official app (`YunTechApp.Helpers.CryptUtils` /
/// `HelperBase.GetNonce`); see `docs/mobile_api.md`.
class YuntechAppCrypto {
  YuntechAppCrypto._();

  // AES key/salt for the nonce, reconstructed from HelperBase's split constants
  // (aesKey = str1 + str3, aesSalt = str2 + str4).
  static const String _aesKey = '9537730CFB3C11175889F67CF2CD3F09';
  static const String _aesSalt = 'B2B45FE7D3566B34';
  static const String _appId = 'yuntechapp';

  /// SHA-256 as lowercase hex — matches `CryptUtils.GetSha256Hash` (`x2`).
  /// The login password must be hashed with this before being sent.
  static String sha256Hex(String input) {
    final digest = SHA256Digest().process(
      Uint8List.fromList(utf8.encode(input)),
    );
    return _toHex(digest);
  }

  /// Builds the `X-User-Nonce` header value.
  ///
  /// AES-CBC/PKCS7 (Base64) of
  /// `appid=yuntechapp&userid={userId}&ts={unixSeconds}&version={appVersion}`,
  /// with key/IV derived via PBKDF2-HMAC-SHA1(aesKey, aesSalt, 1000) → the
  /// first 16 bytes are the AES key, the next 16 are the IV.
  ///
  /// [now] is injectable for deterministic testing.
  static String buildNonce({
    required String userId,
    required String appVersion,
    DateTime? now,
  }) {
    final ts =
        (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000;
    final plain =
        'appid=$_appId&userid=$userId&ts=$ts&version=$appVersion';

    final derived = _pbkdf2(_aesKey, _aesSalt, 1000, 32);
    final key = Uint8List.sublistView(derived, 0, 16);
    final iv = Uint8List.sublistView(derived, 16, 32);

    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    )..init(
      true,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );

    return base64.encode(cipher.process(Uint8List.fromList(utf8.encode(plain))));
  }

  static Uint8List _pbkdf2(
    String password,
    String salt,
    int iterations,
    int length,
  ) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA1Digest(), 64))
      ..init(
        Pbkdf2Parameters(
          Uint8List.fromList(utf8.encode(salt)),
          iterations,
          length,
        ),
      );
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static String _toHex(List<int> bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
