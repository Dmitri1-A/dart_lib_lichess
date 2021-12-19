/// Класс-исключение для библиотеки
class LichessException implements Exception {
  /// Сообщение об ошибке
  final dynamic message;

  LichessException([this.message]);
}
