import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Класс для генерации CodeVerifier, State и Challenge
class OAuthGenerators {
  /// Генерирует CodeVerifier
  static String generateRandomCodeVerifier() {
    Random random = new Random();
    const String chars = "abcdefghijklmnopqrstuvwxyz123456789-_";

    var code = List.generate(
        128, (index) => chars[random.nextInt(chars.length)],
        growable: false);

    return code.join("");
  }

  static String encodeToString(String str) {
    Codec<String, String> stringToBase64Url = utf8.fuse(base64Url);
    String encoded = stringToBase64Url.encode(str);
    return encoded
        .replaceAll(RegExp(r"="), "")
        .replaceAll(RegExp(r"\\+"), "-")
        .replaceAll(RegExp(r"\\/"), "_");
  }

  /// Генерирует CodeChallenge
  static String generateCodeChallenge(String codeVerifier) {
    var bytes = utf8.encode(codeVerifier);
    Digest digest = sha256.convert(bytes);

    return encodeToString(digest.bytes.join(""));
  }

  /// Генерирует State
  static String generateRandomState() {
    Random random = new Random();
    var bytes =
        List.generate(16, (index) => random.nextInt(16), growable: false);

    return encodeToString(bytes.join("")).substring(0, 8);
  }
}
