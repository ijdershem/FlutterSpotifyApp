import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spotify/spotify_io.dart';
import 'package:random_string/random_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';
import 'dart:convert' as JSON;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

var client_id;
var client_secret;
var redirect_uri = "http://localhost:3000/callback";
var localhost;


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
                onPressed: () async { 
                  final Token user_token = await _getToken();
                  print(user_token.access_token);
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

  Future<Token> _getToken() async {
    Stream<String> onCode = await _server();
    _auth();
    final String code = await onCode.first;
    print(code);

    Response token_response = await post(
      'https://accounts.spotify.com/api/token',
      headers: {
        'Content-Type' : 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' + base64.encode(utf8.encode(new StringBuffer(client_id + ':' + client_secret).toString()))
      },
      body: { 
        'grant_type' : "authorization_code",
        'code' : code,
        'redirect_uri' : redirect_uri
      }
    );
    // print('Response status: ${token_response.statusCode}');
    // print('Response body: ${token_response.body}');
    return new Token.fromMap(JSON.jsonDecode(token_response.body));
  } 

  Future<Stream<String>> _server() async {
    final StreamController<String> onCode = new StreamController();
    HttpServer server =
      await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 3000);
      server.listen((HttpRequest request) async {
        final String code = request.uri.queryParameters["code"];
        request.response
          ..statusCode = 200
          ..headers.set("Content-Type", ContentType.HTML.mimeType)
          ..write("<html><h1>Logged into Spotify</h1></html>");
        await request.response.close();
        await server.close(force: true);
        onCode.add(code);
        await onCode.close();
      });
    localhost = server;
    return onCode.stream;
  }
}

void _auth() async { 
  var state = randomAlphaNumeric(16);
  var scope = 'user-read-private user-read-email';
  
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

class Token {
  final String access_token;
  final String token_type;
  final String scope;
  final num expires_in;
  final String refresh_token;

  Token(this.access_token, this.token_type, this.scope, this.expires_in, this.refresh_token);
  Token.fromMap(Map<String, dynamic> json)
        : access_token = json['access_token'],
          token_type = json['token_type'],
          scope = json['scope'],
          expires_in = json['expires_in'],
          refresh_token = json['refresh_token'];
}

