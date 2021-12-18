import 'LichessAPI.dart';

Future<void> main() async {
  Lichess lichess = new Lichess();

  lichess.accessToken = "lio_KAqS4lvZXqWzzV0g4cm0p4upYPuKiMp9";
  // String url = await lichess.getAuthUrl();
  // print(url);
  lichess.deleteToken();
}
