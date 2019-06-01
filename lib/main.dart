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
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = false;
  runApp(MyApp());
}

var client_id = '80a3298daea74e078d240a508afcc4c1';
var client_secret = '';
var redirect_uri = "http://localhost:3000/callback";
var localhost;


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spin - A Crowd Sourced Aux Cord',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
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


// Body widget button for sending user authentication request to
// Spotify API
class BodyWidgetState extends State<BodyWidget> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 150.0, bottom: 50.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Choose a Music Service',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                      color: Colors.black.withOpacity(0.8),
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
              ),
              RaisedButton(
                child: Text('Log into Spotify'),
                onPressed: () async { 
                  final Token user_token = await _getToken(); //Returns Token object containing access and refresh tokens
                  print(user_token.access_token);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Send a POST request to the /token endpoint
  // of the Spotify Web API once the user has granted access
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
    return new Token.fromMap(JSON.jsonDecode(token_response.body));
  } 
  
  //  Launch a local host for use with the Spotify Web API
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

// Performs a GET request to the /authorize endpoint
// of the Spotify Web API 
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

// A class to represent the response from an access token request
// to the Spotify Web API
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

