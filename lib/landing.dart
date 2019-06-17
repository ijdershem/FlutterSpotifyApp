import 'dart:async';
import 'dart:io';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spotify/spotify_io.dart';
import 'package:random_string/random_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'main.dart';
import 'spotify.dart';

class Home extends StatelessWidget { 
  final Token user_token;

  Home(@required this.user_token);

  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      body: Center(
        child: RaisedButton( 
          child: Text('Search'),
          onPressed: () async {
            final SearchResponse search_response = await search('Sundara', user_token);
            print(search_response.albums.items);
          },
        ),
      ),
    );
  }
}