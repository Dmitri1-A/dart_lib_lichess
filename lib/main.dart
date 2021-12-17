import 'LichessAPI.dart';

Future<void> main() async {
  Lichess lichess = new Lichess();

  String url = await lichess.getAuthUrl();

  print(url);
}
