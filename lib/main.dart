import 'package:flutter/material.dart';

import 'app.dart';
import 'storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppStorage.open();
  runApp(LanChatApp(storage: storage));
}
