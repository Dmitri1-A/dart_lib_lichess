import 'dart:convert';
import 'dart:io';
import 'OAuthGenerators.dart';
import 'package:http/http.dart' as http;

/// Класс для взаимодействия с LichessAPI
class Lichess {
  /// Полный адрес Lichess
  String lichessUri = "https://lichess.org";

  /// Токен авторизации
  String _accessToken = "";

  /// Возвращает токен
  String get accessToken => _accessToken;

  /// Uri перенаправления
  String _redirectUri = "";

  /// State - параметр запроса
  String _randomState = "";

  /// Идентификатор приложения
  String _clientId = "BoardLichessProject";

  /// Code verifier для получения codeChallenge
  String _codeVerifier = "";

  /// Запускает сервер для получения запроса, который содержит code и state
  ///
  /// После авторизации на Lichess происходит обмен полченного code на токен
  Future<void> serverStart() async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);

    server.forEach((HttpRequest request) {
      var parameters = request.uri.queryParameters;

      if (parameters['state'] == _randomState) {
        if (parameters.containsKey("code")) {
          request.response.write('Теперь вы можете закрыть браузер');
          server.close();

          String code = parameters['code'] ?? "";
          _obtainToken(code);
        }
      } else {
        request.response
            .write('Возможно запрос был перехвачен, попробуйте ещё раз');
        request.response.close();
      }

      request.response.close();
    });

    _redirectUri =
        "http://" + server.address.host + ":" + server.port.toString();
  }

  /// Возвращает Uri для получения кода авторизации (необходимо перейти по ссылке)
  Future<String> getAuthUrl() async {
    if (_redirectUri.isEmpty) {
      await serverStart();
    }

    String codeChallengeMethod = "S256";
    String responseType = "code";
    String scope =
        "email:read+preference:read+challenge:write+challenge:read+bot:play+board:play";

    _codeVerifier = OAuthGenerators.generateRandomCodeVerifier();
    String codeChallenge = OAuthGenerators.generateCodeChallenge(_codeVerifier);
    _randomState = OAuthGenerators.generateRandomState();

    Map<String, String> parameters = {
      "code_challenge_method": codeChallengeMethod,
      "code_challenge": codeChallenge,
      "response_type": responseType,
      "client_id": _clientId,
      "redirect_uri": _redirectUri,
      "scope": scope,
      "state": _randomState
    };

    String paramString = "";

    int len = parameters.length;
    int i = 0;

    for (var item in parameters.entries) {
      paramString += item.key + "=" + item.value;

      if (i < (len - 1)) {
        i++;
        paramString += "&";
      }
    }

    return lichessUri + "/oauth" + "?" + paramString;
  }

  /// Обменивает [code] на токен
  Future<String> _obtainToken(String code) async {
    var url = Uri.parse("https://lichess.org/api/token");

    // http.get(url, )
    var response = await http.post(
      url,
      body: {
        "grant_type": "authorization_code",
        "code": code,
        "code_verifier": _codeVerifier,
        "redirect_uri": _redirectUri,
        "client_id": _clientId
      },
      headers: {
        "content-type": "application/x-www-form-urlencoded",
      },
      encoding: Encoding.getByName('utf-8'),
    );

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      _accessToken = data['access_token'];

      print("token: " + _accessToken);

      deleteToken();

      print("token: " + _accessToken);
    } else {
      print(response.body);
    }

    return _accessToken;
  }

  /// Удаляет текущий токен
  Future<String> deleteToken() async {
    var url = Uri.parse("https://lichess.org/api/token");

    var response = await http.delete(url, headers: {
      "Content-Type": "application/json",
    });

    return response.body;
  }
}
