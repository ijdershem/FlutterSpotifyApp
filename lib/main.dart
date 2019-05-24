import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:spotify/spotify_io.dart';
import 'package:random_string/random_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';
import 'dart:convert' as JSON;

void main() => runApp(MyApp());

var client_id = '80a3298daea74e078d240a508afcc4c1';
var client_secret = '3d647f09c440414d89a15ef97f23f36d';
var redirect_uri;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Node server demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Spotify Authentication')),
        body: BodyWidget(),
      ),
    );
  }
}
class BodyWidget extends StatefulWidget {
  @override
  BodyWidgetState createState() {
    return new BodyWidgetState();
  }
}
class BodyWidgetState extends State<BodyWidget> {
  String host = "http://10.0.2.2:3000";
  String serverResponse = 'Server response';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text('Log into Spotify'),
                onPressed: () {
                  _makeGetRequest();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(serverResponse),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _makeGetRequest() async {
    host = _localhost();
    Response response = await get(host);

    setState(() {
      serverResponse = response.body;
    });
    _auth(host);
  }

  String _localhost() {
    if (Platform.isAndroid)
      return 'http://10.0.2.2:3000';
    else // for iOS simulator
      return 'http://localhost:3000';
  }
}

void _auth(String host) async { 
  var state = randomAlphaNumeric(16);
  var scope = 'user-read-private user-read-email';
  redirect_uri = host + "/callback";
  
  final Map<String, String> authQueryParameters = {
    "client_id": client_id,
    "response_type": 'code',
    "redirect_uri": redirect_uri,
    "scope": scope,
    "state": state,
  };

  Uri authQuery = new Uri(scheme: 'https',
    host: 'accounts.spotify.com',
    path: 'authorize',
    queryParameters: authQueryParameters);

  String url = authQuery.toString();
  if (await canLaunch(url)) {
    print(url); 
    await launch(url);
  } else { 
    throw 'Could not launch $url';
  }
}