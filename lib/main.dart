import 'LichessAPI.dart';

Future<void> main() async {
  Lichess lichess = new Lichess();

  String url = await lichess.getAuthUrl();
  print(url);

  var token = await lichess.getToken();

  print("token after getToken method: " + token);

  await lichess.deleteToken();

  print("token after delete method: " + lichess.accessToken);
}
