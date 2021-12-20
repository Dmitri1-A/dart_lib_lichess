import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'OAuthGenerators.dart';
import 'AppServer.dart';
import 'LichessExeption.dart';

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
  ///
  /// Может вернуть исключение [LichessException] при ошибке
  Future<String> getToken() async {
    var code = await AppServer.getCode(_randomState);

    try {
      _accessToken = await _obtainToken(code);
    } on LichessException catch (error) {
      throw error;
    }

    return _accessToken;
  }

  /// Обменивает [code] на токен
  ///
  /// Может вернуть исключение [LichessException] при ошибке
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
    } else {
      throw LichessException(
          "Не удалось обменять код на токен. Статус код запроса: " +
              response.statusCode.toString());
    }

    return _accessToken;
  }

  /// Удаляет текущий токен
  ///
  /// Может вернуть исключение [LichessException] при ошибке
  Future<void> deleteToken() async {
    var url = Uri.parse(lichessUri + "/api/token");

    var response = await http
        .delete(url, headers: {"authorization": "Bearer " + _accessToken});

    if (response.statusCode == 204) {
      _accessToken = "";
    } else
      throw new LichessException(
          "Не удалось удалить токен. Статус код запроса: " +
              response.statusCode.toString());
  }

  /// Прекращает игру с AI
  ///
  /// [gameId] - Идентификатор игры
  ///
  /// Метод может вернуть исключение [LichessException]
  ///
  /// Возвращает [dynamic]. Как работать с возвращаемыми данными смотрите
  /// в описании метода [startGameAI]
  ///
  /// Если запрос был выполнен успешно:
  ///```json
  /// {
  ///  "ok": true
  ///  }
  ///```
  ///
  /// Если запрос не был выполнен:
  ///
  ///```json
  /// {
  ///  "error": "This request is invalid because [...]"
  /// }
  ///```
  ///
  /// Также формат возвращаемых данных можно посмотреть по ссылке:
  /// * https://lichess.org/api#operation/boardGameAbort
  Future<dynamic> abortGameAI(String gameId) async {
    var url = Uri.parse(lichessUri + "/api/board/game/" + gameId + "/abort");

    var response = await http.post(
      url,
      headers: {
        "authorization": "Bearer " + _accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );

    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new LichessException(
          "Не удалось прекратить игру. Статус код запроса: " +
              response.statusCode.toString());
    }

    return jsonDecode(response.body);
  }

  /// Начинает поиск игры с реальным человеком
  ///
  /// [time] - [ 0 .. 180 ] Начальное время в минутах
  ///
  /// [increment] - [ 0 .. 180 ] время в секундах
  ///
  /// [days] - Enum: 1 3 5 7 10 14 дней на ход
  ///
  /// [variant] - "standard" (default) "chess960" "crazyhouse" "antichess"
  /// "atomic" "horde" "kingOfTheHill" "racingKings" "threeCheck"
  ///
  /// [color] - "random" "white" "black"
  ///
  /// Если не удалось осуществить поиск генерирует исключение [LichessException]
  void seekPlayer(String time, String increment, String days, String variant,
      String color) async {
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
        "authorization": "Bearer " + _accessToken,
        "accept": "text/plain"
      },
      encoding: Encoding.getByName('utf-8'),
    );

    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new LichessException(
          "Не удалось осуществить поиск игрока. Статус код запроса: " +
              response.statusCode.toString());
    }
  }

  /// Начинает игру с компьютером.
  ///
  /// [level] - уровень от 1 .. 8
  ///
  /// [clockLimit] - [ 0 .. 10800 ], если пустой, то игра по переписке
  ///
  /// [clockIncrement] - [ 0 .. 60 ] увеличение времени в секундах.
  ///
  /// [days] - [ 1 .. 15 ] дней на ход, настройки времени должны быть пропущены
  ///
  /// [color] - "random" "white" "black"
  ///
  /// [variant] - "standard" (default) "chess960" "crazyhouse" "antichess" "atomic" "horde" "kingOfTheHill" "racingKings" "threeCheck"
  ///
  /// Возвращаемая json строка преобразуется в dynamic.
  /// Обращаться к полям можно следующим образом:
  ///
  ///```dart
  ///   var lichess = new Lichess();
  ///   //... здесь может быть установка токена или его получение
  ///   var gameData = await lichess.startGameAI();
  ///   gameData["id"]; // Доступ к полю
  ///```
  ///
  /// Формат json:
  ///
  ///```json
  ///{
  ///   "id": "q7ZvsdUF",
  ///   "rated": true,
  ///   "variant": "standard",
  ///   "speed": "blitz",
  ///   "perf": "blitz",
  ///   "createdAt": 1514505150384,
  ///   "lastMoveAt": 1514505592843,
  ///   "status": "draw",
  ///   "players": {
  ///     "white": {
  ///       "user": {
  ///         "name": "Lance5500",
  ///         "title": "LM",
  ///         "patron": true,
  ///         "id": "lance5500"
  ///       },
  ///       "rating": 2389,
  ///       "ratingDiff": 4
  ///     },
  ///     "black": {
  ///       "user": {
  ///         "name": "TryingHard87",
  ///         "id": "tryinghard87"
  ///       },
  ///       "rating": 2498,
  ///       "ratingDiff": -4
  ///     }
  ///   },
  ///   "opening": {
  ///     "eco": "D31",
  ///     "name": "Semi-Slav Defense: Marshall Gambit",
  ///     "ply": 7
  ///   },
  ///   "moves": "d4 d5 c4 c6 Nc3 e6 e4 Nd7 exd5 cxd5 cxd5 exd5 Nxd5 Nb6 Bb5+ Bd7 Qe2+ Ne7 Nxb6 Qxb6 Bxd7+ Kxd7 Nf3 Qa6 Ne5+ Ke8 Qf3 f6 Nd3 Qc6 Qe2 Kf7 O-O Kg8 Bd2 Re8 Rac1 Nf5 Be3 Qe6 Rfe1 g6 b3 Bd6 Qd2 Kf7 Bf4 Qd7 Bxd6 Nxd6 Nc5 Rxe1+ Rxe1 Qc6 f3 Re8 Rxe8 Nxe8 Kf2 Nc7 Qb4 b6 Qc4+ Nd5 Nd3 Qe6 Nb4 Ne7 Qxe6+ Kxe6 Ke3 Kd6 g3 h6 Kd3 h5 Nc2 Kd5 a3 Nc6 Ne3+ Kd6 h4 Nd8 g4 Ne6 Ke4 Ng7 Nc4+ Ke6 d5+ Kd7 a4 g5 gxh5 Nxh5 hxg5 fxg5 Kf5 Nf4 Ne3 Nh3 Kg4 Ng1 Nc4 Kc7 Nd2 Kd6 Kxg5 Kxd5 f4 Nh3+ Kg4 Nf2+ Kf3 Nd3 Ke3 Nc5 Kf3 Ke6 Ke3 Kf5 Kd4 Ne6+ Kc4",
  ///   "clock": {
  ///     "initial": 300,
  ///     "increment": 3,
  ///     "totalTime": 420
  ///   }
  /// }
  ///```
  ///
  /// Также формат возвращаемых данных можно посмотреть по ссылке:
  /// * https://lichess.org/api#operation/challengeAi
  Future<dynamic> startGameAI(String level, String clockLimit,
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
        "authorization": "Bearer " + _accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );
    var statusCode = response.statusCode;

    if ((statusCode != 200) && (statusCode != 201)) {
      throw new LichessException(
          "Не удалось начать игру, код ошибки:" + statusCode.toString());
    }

    return jsonDecode(response.body);
  }

  ///Отменяет игру
  ///
  /// [gameId] - Идентификатор игры
  ///
  /// Возвращает [dynamic]. Как работать с возвращаемыми данными смотрите
  /// в описании метода [startGameAI]
  ///
  ///Если запрос был выполнен успешно:
  ///
  ///```json
  ///{
  /// "ok": true
  /// }
  ///```
  ///
  ///Если запрос не был выполнен:
  ///
  ///```json
  ///{
  /// "error": "This request is invalid because [...]"
  /// }
  ///```
  ///
  /// Также формат возвращаемых данных можно посмотреть по ссылке:
  /// * https://lichess.org/api#operation/boardGameResign
  Future<dynamic> resignGame(String gameId) async {
    var url = Uri.parse(lichessUri + "/api/board/game/" + gameId + "/resign");

    var response = await http.post(
      url,
      headers: {
        "authorization": "Bearer " + _accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );
    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new LichessException(
          "Не удалось прекратить игру. Статус код запроса: " +
              response.statusCode.toString());
    }

    return jsonDecode(response.body);
  }

  /// Сделать ход в игре
  ///
  /// [gameId] - Идентификатор игры
  ///
  /// [move] - Ход в формате UCI
  ///
  /// Возвращает [dynamic]. Как работать с возвращаемыми данными смотрите
  /// в описании метода [startGameAI]
  ///
  ///Если запрос был выполнен успешно:
  ///
  ///```json
  ///{
  /// "ok": true
  /// }
  ///```
  ///
  ///Если запрос не был выполнен:
  ///
  ///```json
  ///{
  /// "error": "This request is invalid because [...]"
  /// }
  ///```
  ///
  /// Также формат возвращаемых данных можно посмотреть по ссылке:
  /// * https://lichess.org/api#operation/boardGameMove
  Future<dynamic> makeMove(String gameId, String move) async {
    var url =
        Uri.parse(lichessUri + "/api/board/game/" + gameId + "/move/" + move);

    var response = await http.post(
      url,
      headers: {
        "authorization": "Bearer " + _accessToken,
        "accept": "application/json"
      },
      encoding: Encoding.getByName('utf-8'),
    );
    var statusCode = response.statusCode;

    if (statusCode != 200) {
      throw new Exception("Не удалось сделать ход. Статус код запроса: " +
          response.statusCode.toString());
    }

    return jsonDecode(response.body);
  }

  /// Функция трансляции состояния игры.
  Stream<dynamic> listenStreamGameState(String gameId) async* {
    var url = Uri.parse(lichessUri + "/api/board/game/stream/" + gameId);

    http.Request request = http.Request("GET", url);
    request.headers['authorization'] = 'Bearer ' + _accessToken;
    request.headers['accept'] = 'application/json';

    var streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw new Exception(
          "Не удалось получить состояние игры. Статус код запроса: " +
              streamedResponse.statusCode.toString());
    }

    await for (var item in streamedResponse.stream) {
      var str = utf8.decoder.convert(item);

      str = str.trim();

      if (str.length > 0) yield jsonDecode(str);
    }
  }
}
