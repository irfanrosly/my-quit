import 'package:flutter/material.dart';
import 'chatbot/myquitmate_chatbot.dart'; // import relatif, paling selamat

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyQuitMateChatBot(),
  ));
}
