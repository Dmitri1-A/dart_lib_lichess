import 'dart:convert';
import 'package:http/http.dart' as http;

import 'OAuthGenerators.dart';
import 'AppServer.dart';

/// Класс для взаимодействия с LichessAPI
class Lichess {
  /// Полный адрес Lichess
  String lichessUri = "https://lichess.org";

  /// Токен авторизации
  static String _accessToken = "";

  /// Возвращает токен
  String get accessToken => _accessToken;

  set accessToken(value) => _accessToken = value;

  /// Uri перенаправления
  String _redirectUri = "";

  /// State - параметр запроса
  String _randomState = "";

  /// Идентификатор приложения
  String _clientId = "BoardLichessProject";

  /// Code verifier для получения codeChallenge
  String _codeVerifier = "";

  /// Возвращает Uri для получения кода авторизации (необходимо перейти по ссылке)
  /// Запускает сервер, но не слушает запросы
  /// После вызова этого метода нужно вызвать [getToken]
  Future<String> getAuthUrl() async {
    _redirectUri = await AppServer.serverStart();

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

  /// Возвращает токен
  ///
  /// Начинает слушать запросы, приходящие на сервер.
  /// После получения 1 запроса сервер закрывается.
  /// Можно вызвать без await, токен сохраниться в [accessToken]
  Future<String> getToken() async {
    var code = await AppServer.getCode(_randomState);
    _accessToken = await _obtainToken(code);

    return _accessToken;
  }

  /// Обменивает [code] на токен
  Future<String> _obtainToken(String code) async {
    dynamic data;
    var url = Uri.parse(lichessUri + "/api/token");

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
      data = jsonDecode(response.body);
      _accessToken = data['access_token'];
    }

    return _accessToken;
  }

  /// Удаляет текущий токен
  Future<String> deleteToken() async {
    var url = Uri.parse(lichessUri + "/api/token");

    var response = await http
        .delete(url, headers: {"authorization": "Bearer " + _accessToken});

    if (response.statusCode == 204) {
      _accessToken = "";
    }

    return response.body;
  }

  /// Прекращает игру с AI
  Future<String> abortGameAI(String gameId) async {
    var url = Uri.parse(lichessUri + "/api/board/game/" + gameId + "/abort");

    var response = await http.post(
      url,
      headers: {
        "authorization": "Bearer " + accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );

    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new Exception("Не удалось прекратить игру");
    }

    return response.body;
  }

  /// Начинает поиск игры с реальным человеком
  Future<String> seekPlayer(String time, String increment, String days,
      String variant, String color) async {
    var url = Uri.parse(lichessUri + "/api/board/seek");

    var response = await http.post(
      url,
      body: {
        "rated": "false",
        "time": time,
        "increment": increment,
        "days": days,
        "color": color,
        "variant": variant,
        "ratingRange": ""
      },
      headers: {
        "content-type": "application/x-www-form-urlencoded",
        "authorization": "Bearer " + accessToken,
        "accept": "text/plain"
      },
      encoding: Encoding.getByName('utf-8'),
    );

    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new Exception("Не удалось осуществить поиск");
    }

    return response.body;
  }

  ///Начинает игру с компьютером
  Future<String> startGameAI(String level, String clockLimit,
      String clockIncrement, String days, String color, String variant) async {
    var url = Uri.parse(lichessUri + "/api/challenge/ai");

    var response = await http.post(
      url,
      body: {
        "level": level,
        "clock.limit": clockLimit,
        "clock.increment": clockIncrement,
        "days": days,
        "color": color,
        "variant": variant,
        "fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
      },
      headers: {
        "content-type": "application/x-www-form-urlencoded",
        "authorization": "Bearer " + accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );
    var statusCode = response.statusCode;

    if ((statusCode != 200) && (statusCode != 201)) {
      throw new Exception(
          "Не удалось начать игру, код ошибки:" + statusCode.toString());
    }

    return response.body;
  }

  ///Отменяет игру
  Future<String> resignGame(String gameId) async {
    var url = Uri.parse(lichessUri + "/api/board/game/" + gameId + "/resign");

    var response = await http.post(
      url,
      headers: {
        "authorization": "Bearer " + accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );
    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new Exception("Не удалось прекратить игру");
    }

    return response.body;
  }
}
