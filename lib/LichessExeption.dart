/// Класс-исключение для библиотеки
class LichessException implements Exception {
  final dynamic message;

  LichessException([this.message]);
}
