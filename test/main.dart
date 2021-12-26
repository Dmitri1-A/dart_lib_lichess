import 'package:lichess/LichessAPI.dart';
import 'package:lichess/LichessExeption.dart';

// import '../lib/LichessAPI.dart';
// import '../lib/LichessExeption.dart';

Future<void> main() async {
  try {
    LichessAPI lichess = new LichessAPI();

    String url = await lichess.getAuthUrl();
    print(url);

    var token = await lichess.getToken();
    print(token);
    // lichess.accessToken = "lio_lId2cuzlLWyodryfmk1PDxkydueQxvVR";

    var email = await lichess.getEmailAddress();
    print("email: " + email['email']);

    var profile = await lichess.getProfile();
    print("username: " + profile['username']);

    await lichess.deleteToken();
    // var gameData =
    //     await lichess.startGameAI("1", "", "", "1", "white", "standard");

    // var gameId = gameData["id"];
    // print("status game: " + gameData["status"]["name"]);
    // print(lichess.lichessUri + "/" + gameId);

    // var stream = await lichess.listenStreamGameState(gameId);

    // await for (var str in stream) {
    //   switch (str['type']) {
    //     case 'gameFull':
    //       print(str['state']['moves']);
    //       break;
    //     case 'gameState':
    //       print(str['moves']);
    //       break;
    //   }
    // }

    // var stream = await lichess.listenStreamIncomingEvents();

    // lichess.seekPlayer('6', '30', '', 'standard', 'random');

    // var gameId = "";

    // await for (var str in stream) {
    //   switch (str['type']) {
    //     case 'gameStart':
    //     case 'gameFinish':
    //       gameId = str['game']['id'];
    //       break;
    //     case 'challenge':
    //     case 'challengeCanceled':
    //     case 'challengeDeclined':
    //       gameId = str['challenge']['id'];
    //       break;
    //   }

    //   print("type: " + str['type']);
    //   print(lichess.lichessUri + "/" + gameId);

    //   lichess.listenClose = true;

    //   break;
    // }
  } on LichessException catch (ex) {
    print(ex.message);
  }
}
