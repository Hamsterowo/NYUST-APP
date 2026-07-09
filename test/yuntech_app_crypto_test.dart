import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:yun_tool/utils/yuntech_app_crypto.dart';

// Reversed constants, duplicated here so the test independently re-derives the
// key and decrypts the nonce produced by the production code.
const _aesKey = '9537730CFB3C11175889F67CF2CD3F09';
const _aesSalt = 'B2B45FE7D3566B34';

Uint8List _pbkdf2(String password, String salt, int iterations, int length) {
  final d = PBKDF2KeyDerivator(HMac(SHA1Digest(), 64))
    ..init(
      Pbkdf2Parameters(
        Uint8List.fromList(utf8.encode(salt)),
        iterations,
        length,
      ),
    );
  return d.process(Uint8List.fromList(utf8.encode(password)));
}

String _decryptNonce(String base64Nonce) {
  final derived = _pbkdf2(_aesKey, _aesSalt, 1000, 32);
  final cipher =
      PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))..init(
        false,
        PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
          ParametersWithIV<KeyParameter>(
            KeyParameter(Uint8List.sublistView(derived, 0, 16)),
            Uint8List.sublistView(derived, 16, 32),
          ),
          null,
        ),
      );
  return utf8.decode(cipher.process(base64.decode(base64Nonce)));
}

void main() {
  group('YuntechAppCrypto', () {
    test('sha256Hex matches the known vector for "test"', () {
      expect(
        YuntechAppCrypto.sha256Hex('test'),
        '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      );
    });

    test('sha256Hex is lowercase 64-char hex', () {
      final hash = YuntechAppCrypto.sha256Hex('P@ssw0rd!');
      expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('buildNonce round-trips to the expected plaintext', () {
      final now = DateTime.utc(2026, 1, 2, 3, 4, 5);
      final ts = now.millisecondsSinceEpoch / 1000.0;

      final nonce = YuntechAppCrypto.buildNonce(
        userId: 'D11012345',
        appVersion: '1.10.3',
        now: now,
      );

      expect(
        _decryptNonce(nonce),
        'appid=yuntechapp&userid=D11012345&ts=$ts&version=1.10.3',
      );
    });

    test('buildNonce output is valid base64', () {
      final nonce = YuntechAppCrypto.buildNonce(
        userId: 'D11012345',
        appVersion: '1.10.3',
      );
      expect(() => base64.decode(nonce), returnsNormally);
    });
  });
}
