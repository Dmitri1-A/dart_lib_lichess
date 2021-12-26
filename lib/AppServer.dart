import 'dart:io';
import 'LichessAPI.dart';

/// Класс для запуска сервера и прослушивания входящих запросов.
///
/// Используется классом [Lichess]
class AppServer {
  static HttpServer? _server;

  HttpServer? get server => _server;

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

      request.response.headers
          .add(HttpHeaders.contentTypeHeader, "text/html; charset=UTF-8");

      if (parameters['state'] == state) {
        if (parameters.containsKey("code")) {
          request.response.write('''<!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Document</title>
      </head>
      <body>
          <h1>Теперь вы можете закрыть Браузер</h1>
      </body>
      </html>''');
          code = parameters['code'] ?? "";
        }
      } else {
        request.response.write('''<!DOCTYPE html>
          <html lang="en">
          <head>
              <meta charset="UTF-8">
              <meta http-equiv="X-UA-Compatible" content="IE=edge">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Document</title>
          </head>
          <body>
              <h1>Возможно запрос был перехвачен, попробуйте ещё раз</h1>
          </body>
          </html>''');
      }

      _server?.close();
      request.response.close();
    });

    return code;
  }
}
