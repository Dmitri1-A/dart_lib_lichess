import 'package:lichess/LichessExeption.dart';

import 'LichessAPI.dart';
import 'LichessExeption.dart';

Future<void> main() async {
  Lichess lichess = new Lichess();

  // String url = await lichess.getAuthUrl();
  // print(url);

  // var token = await lichess.getToken();
  // print(token);
  // await lichess.deleteToken();
  // lichess.accessToken = "lio_7ZAT0uRtfgHM9ymJVDrjdYTyPg7eVQIU";
  // var gameData =
  //     await lichess.startGameAI("1", "", "", "1", "white", "standard");
  // print(gameData["id"]);

  try {
    lichess.resignGame("1");
  } on LichessException catch (e) {
    print(e.message);
  }
}
