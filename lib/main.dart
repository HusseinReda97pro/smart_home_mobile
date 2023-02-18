import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Smart Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool switchState = false;
  DatabaseReference ref =
      FirebaseDatabase.instance.ref("smart_home/switch_state");
  late SpeechToText _speech;
  bool _isListening = false;
  late var locales;
  var selectedLocale;

  @override
  void initState() {
    _getSwitchState();
    _speech = SpeechToText();
    // getLocals();
    super.initState();

    ///whatever you want to run on page build
  }

  // getLocals() async {
  //   var locales = await _speech.locales();
  //   print(locales);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: switchState ? Colors.grey : Colors.black26,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await _setSwitchState();
                _getSwitchState();
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: !switchState ? Colors.amber : Colors.black,
                minimumSize: const Size(200, 90),
                maximumSize: const Size(200, 90),
              ),
              child: Icon(
                switchState ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 46,
              ),
            ),
            const SizedBox(
              height: 15.0,
            ),
            Text(
              "Switch: ${switchState ? "ON" : "OFF"}".toString(),
              style: TextStyle(
                  color: switchState ? Colors.black : Colors.white,
                  fontSize: 34),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Colors.redAccent,
        endRadius: 80,
        duration: const Duration(seconds: 2),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          backgroundColor: Colors.redAccent,
          onPressed: () => _onListen(),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
          ),
        ),
      ),
    );
  }

  void _getSwitchState() {
    ref.onValue.listen((DatabaseEvent event) {
      var data = event.snapshot.value;
      if (data == 0) switchState = false;
      if (data == 1) switchState = true;
      setState(() {});
    });
  }

  Future<void> _setSwitchState() async {
    await ref.set(switchState ? 0 : 1);
  }

  Future<void> _onListen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
          onStatus: (val) => {print("onStatus $val")},
          onError: (val) => {print("onStatus $val")});
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
            // localeId: selectedLocale.localeId,
            localeId: 'ar',
            onResult: (val) {
              if (val.finalResult) {
                print('val.recognizedWords: ${val.recognizedWords}');
                _processCommand(val.recognizedWords);
                setState(() {
                  _isListening = false;
                  _speech.stop();
                });
              }
            });
      } else {
        print("The user has denied the use of speech recognition.");
        setState(() {
          _isListening = false;
          _speech.stop();
        });
      }
    }
  }

  void _processCommand(String command) async {
    if (command.isNotEmpty) {
      if (command == "افتح النور") {
        await ref.set(1);
      }
      if (command == "اقفل النور") {
        await ref.set(0);
      }
    }
  }
}
