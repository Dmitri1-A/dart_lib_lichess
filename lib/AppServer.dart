import 'dart:io';
import 'LichessAPI.dart';

/// Класс для запуска сервера и прослушивания входящих запросов.
///
/// Используется классом [Lichess]
class AppServer {
  static HttpServer? _server;

  /// Запускает сервер для получения запроса, который содержит code и state
  static Future<String> serverStart() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

    String host = _server?.address.host ?? "";
    String port = _server?.port.toString() ?? "";

    return "http://" + host + ":" + port;
  }

  /// Обрабатывает входящий запрос и возвращает параметр code
  static Future<String> getCode(String state) async {
    String code = "";

    await _server?.forEach((HttpRequest request) {
      var parameters = request.uri.queryParameters;

      if (parameters['state'] == state) {
        if (parameters.containsKey("code")) {
          request.response.write('Теперь вы можете закрыть браузер');
          code = parameters['code'] ?? "";
        }
      } else {
        request.response
            .write('Возможно запрос был перехвачен, попробуйте ещё раз');
      }

      _server?.close();
      request.response.close();
    });

    return code;
  }
}
