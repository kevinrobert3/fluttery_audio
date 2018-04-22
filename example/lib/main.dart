import 'package:flutter/material.dart';
import 'package:fluttery_audio_example/declarative_audio_example.dart';
import 'package:logging/logging.dart';

const SOUNDCLOUD_ID_ELECTRO_MONOTONY = "266891990";
const SOUNDCLOUD_ID_DEBUT_TRANCE = "260578593";
const SOUNDCLOUD_ID_DEBUT = "258735531";
const SOUNDCLOUD_ID_MASTERS_TRANCE = "9540779";
const SOUNDCLOUD_ID_MASTERS_TRIBAL = "9540352";
const SOUNDCLOUD_OTHER = "295692063";
const STREAM_URL = "https://api.soundcloud.com/tracks/" + SOUNDCLOUD_ID_DEBUT_TRANCE +"/stream?secret_token=s-tj3IS&client_id=LBCcHmRB8XSStWL6wKH2HPACspQlXg2P";

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Fluttery Audio'),
        ),
        body: new Center(
//          child: new DeclarativeAudioSimpleExample(
//            audioUrl: STREAM_URL,
//          ),
          child: new DeclarativeAudioComponentsExample(
            audioUrl: STREAM_URL,
          ),
//          child: new ImperativeAudioExample(
//            audioUrl: STREAM_URL,
//          ),
        ),
      ),
    );
  }
}
