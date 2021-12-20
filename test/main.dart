import '../lib/LichessAPI.dart';
// import '../lib/LichessExeption.dart';

Future<void> main() async {
  Lichess lichess = new Lichess();

  // String url = await lichess.getAuthUrl();
  // print(url);

  // var token = await lichess.getToken();
  // print(token);
  // await lichess.deleteToken();
  lichess.accessToken = "lio_7ZAT0uRtfgHM9ymJVDrjdYTyPg7eVQIU";
  var gameData =
      await lichess.startGameAI("1", "", "", "1", "white", "standard");

  var gameId = gameData["id"];
  print("status game: " + gameData["status"]["name"]);
  print(lichess.lichessUri + "/" + gameId);

  var stream = await lichess.listenStreamGameState(gameId);

  await for (var str in stream) {
    switch (str['type']) {
      case 'gameFull':
        print(str['state']['moves']);
        break;
      case 'gameState':
        print(str['moves']);
        break;
    }
  }
}
