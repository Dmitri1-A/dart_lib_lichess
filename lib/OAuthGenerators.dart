import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Класс для генерации CodeVerifier, State и Challenge
class OAuthGenerators {
  /// Генерирует CodeVerifier
  static String generateRandomCodeVerifier() {
    Random random = new Random();

    var bytes =
        List.generate(64, (index) => random.nextInt(128), growable: false);

    return encodeToString(bytes);
  }

  /// Генерирует CodeChallenge по [codeVerifier]
  static String generateCodeChallenge(String codeVerifier) {
    var bytes = ascii.encode(codeVerifier);
    Digest digest = sha256.convert(bytes);

    return encodeToString(digest.bytes);
  }

  /// Генерирует State
  static String generateRandomState() {
    Random random = new Random();
    var bytes =
        List.generate(16, (index) => random.nextInt(128), growable: false);

    return encodeToString(bytes).substring(0, 8);
  }

  /// Кодирует [bytes] по Base64Url
  static String encodeToString(List<int> bytes) {
    return base64UrlEncode(bytes)
        .replaceAll(RegExp(r"="), "")
        .replaceAll(RegExp(r"\\+"), "-")
        .replaceAll(RegExp(r"\\/"), "_");
  }
}
