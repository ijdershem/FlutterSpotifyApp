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

Future<SearchResponse> search(var query, Token user_token) async { 
  var endpoint = 'https://api.spotify.com/v1/search';
  var type = 'track,album,artist';
  Response search_response = await get( 
    endpoint + '?q=${query}&type=${type}&limit=1&market=US&offset=0',
    headers: { 
      'Authorization': 'Bearer ${user_token.access_token}',
    },
  );

  print(search_response.body);
  return new SearchResponse.fromMap(jsonDecode(search_response.body));
}

class SearchResponse { 
  ResultList albums;
  ResultList artists;
  ResultList tracks;

  SearchResponse({ 
    this.albums,
    this.artists,
    this.tracks
  });
  SearchResponse.fromMap(Map<String, dynamic> json) { 
    if (json['albums'] != null) albums = new ResultList.fromMap(json['albums'], 'albums');
    if (json['artists'] != null) artists = new ResultList.fromMap(json['artists'], 'artists');
    if (json['tracks'] != null) tracks = new ResultList.fromMap(json['tracks'], 'tracks');
  } 
}

class ResultList { 
  String href;
  List<dynamic> items; //list of album, artist, or track objects
  num limit;
  String next;
  num offset;
  String previous;
  num total;
  String type; //type of ResultList; albums, artists, or tracks

  ResultList({ 
    this.href,
    this.items,
    this.limit,
    this.next,
    this.offset,
    this.previous,
    this.total,
    this.type
  });

  ResultList.fromMap(Map<String, dynamic> json, String type) { 
    this.href = json['href'];
    this.items = buildItemList(json['items'], type); //convert to List<dynamic>
    this.limit = json['limit'];
    this.next = json['next'];
    this.offset = json['offset'];
    this.previous = json['previous'];
    this.total = json['total'];
    this.type = type;
  }
}

List<dynamic> buildItemList(List<dynamic> resultObject, String type) {
  List<dynamic> resultList = new List<dynamic>();

  switch(type) { 
    case 'albums': { 
      print("Making album list"); 
      resultList = buildAlbumList(resultObject);
    }
    break;
    case 'artists': { 
      print("Making artist object"); 
      resultList = buildArtistList(resultObject);
    }
    break;
    case 'tracks': { 
      print("Making track object"); 
      resultList = buildTrackList(resultObject);
    }
    break;
    default: { print("Error in response"); }
    break;
  }
  return resultList;
}

class Track {
  //Track values
  Album album; //should be simplified album object
  List<ArtistSmpl> artists; //should be simplified artist objects
  List<String> available_markets;
  num disc_number;
  num duration_ms;
  bool explicit; //might need to be string('yes' or 'no')
  Map<String, dynamic> external_ids;  //{key}(string), {value}(string)
  Map<String, dynamic> external_urls; //{key}(string), {value}(string)
  String href;
  String id;
  bool is_playable; //only part of response when Track Relinking is applied; may cause issue if not?
  LinkedTrack linked_from; //only part of response when Track Relinking is applied; may cause issue if not?
  Map<String, dynamic> restrictions;
  String name;
  num popularity;
  String preview_url;
  num track_number;
  String type;
  String uri;
  bool is_local;
  
  Track({ 
    this.album,
    this.artists,
    this.available_markets,
    this.disc_number,
    this.duration_ms,
    this.explicit,
    this.external_ids,
    this.external_urls,
    this.href,
    this.id,
    this.is_playable,
    this.linked_from,
    this.restrictions,
    this.name,
    this.popularity,
    this.preview_url,
    this.track_number,
    this.type,
    this.uri,
    this.is_local
  });
  Track.fromMap(Map<String, dynamic> json) { 
    var list_artists = json['artists'] as List;
    List<ArtistSmpl> artistsList = buildArtistSmplList(list_artists);

    if(json['available_markets'] != null) { 
      this.available_markets = new List<String>.from(json['available_markets']);
    } //Convert to List<String> if available_markets provided

    if(json['linked_from'] != null) { 
      this.linked_from = new LinkedTrack.fromMap(json['linked_from']);
    } //Convert to LinkedTrack object if linked_form is provided

    this.album = Album.fromMap(json['album']);
    this.artists = artistsList;
    this.disc_number = json['disc_number'];
    this.duration_ms = json['duration_ms'];
    this.explicit = json['explicit'];
    this.external_ids = json['external_ids'];
    this.external_urls = json['external_urls'];
    this.href = json['href'];
    this.id = json['id'];
    this.is_playable = json['is_playable']; 
    this.restrictions = json['restrictions'];
    this.name = json['name'];
    this.popularity = json['popularity'];
    this.preview_url = json['preview_url'];
    this.track_number = json['track_number'];
    this.type = json['type'];
    this.uri = json['uri'];
    this.is_local = json['is_local'];
  }
}

List<Track> buildTrackList(List<dynamic> trackItems) { 
  num i = 0;
  List<Track> tracksList = new List<Track>();

  trackItems.forEach((n) { 
    print('Item $i:');
    Track track = new Track.fromMap(n);
    tracksList.add(track);
    i++;
  });
  return tracksList;
} //Properly building list of tracks

class Album { 
  //Album values (simplified)
  String album_type;
  List<ArtistSmpl> artists;
  List<String> available_markets; //may cause issue if it doesn't exist?
  Map<String, dynamic> external_urls;
  String href;
  String id;
  List<Image> images; //height(int), url(string), width(int)
  String name;
  String release_date;
  String release_date_precision;
  Map<String, dynamic> restrictions; //may cause issue if it doesn't exist?
  String type;
  String uri;

  Album({ 
    this.album_type,
    this.artists,
    this.available_markets,
    this.external_urls,
    this.href,
    this.id,
    this.images,
    this.name,
    this.release_date,
    this.release_date_precision,
    this.restrictions,
    this.type,
    this.uri
  });
  Album.fromMap(Map<String, dynamic> json) { 
    var list_artists = json['artists'];
    var list_images = json['images'];
    List<ArtistSmpl> artistsList = buildArtistSmplList(list_artists);
    List<Image> imagesList = buildImageList(list_images);

    if(json['available_markets'] != null) { 
      this.available_markets = new List<String>.from(json['available_markets']);
    } //Convert to List<String> if available_markets provided

    this.album_type = json['album_type'];
    this.artists = artistsList; //convert to List<ArtistSmpl>
    this.external_urls = json['external_urls'];
    this.href = json['href'];
    this.id = json['id'];
    this.images = imagesList; //convert to List<Image>
    this.name = json['name'];
    this.release_date = json['release_date'];
    this.release_date_precision = json['release_date_precision'];
    this.restrictions = json['restrictions']; //only part of response when Track Relinking is applied; may cause issue if not?
    this.type = json['type'];
    this.uri = json['uri'];
  }
}

List<Album> buildAlbumList(List<dynamic> albumItems) { 
  num i = 0;
  List<Album> albumsList = new List<Album>();

  albumItems.forEach((n) { 
    print('Item $i:');
    // print(n);
    Album album = new Album.fromMap(n);
    albumsList.add(album);
    i++;
  });
  return albumsList;
} 

class Artist { 
  //Artist values
  Map<String, dynamic> external_urls;
  Map<String, dynamic> followers; //href(string), total(int)
  List<String> genres;
  String href;
  String id;
  List<Image> images; //height(int), url(string), width(int)
  String name;
  num popularity;
  String type;
  String uri;

  Artist({ 
    this.external_urls,
    this.followers,
    this.genres,
    this.href,
    this.id,
    this.images,
    this.name,
    this.popularity,
    this.type,
    this.uri
  });
  Artist.fromMap(Map<String, dynamic> json) {
    var list_images = json['images'];
    List<Image> imagesList = buildImageList(list_images);

    this.external_urls = json['external_urls'];
    this.followers = json['followers'];
    this.genres = new List<String>.from(json['genres']); //convert to List<String>
    this.href = json['href'];
    this.id = json['id'];
    this.images = imagesList; //convert to List<Image>. May need to initialize json['images'] as List
    this.name = json['name'];
    this.popularity = json['popularity'];
    this.type = json['type'];
    this.uri = json['uri'];
  }
}

List<Artist> buildArtistList(List<dynamic> artistItems) { 
  num i = 0;
  List<Artist> artistsList = new List<Artist>();

  artistItems.forEach((n) { 
    print('Item $i:');
    Artist artist = new Artist.fromMap(n);
    artistsList.add(artist);
    i++;
  });
  return artistsList;
} //Properly building list of artists

class ArtistSmpl { 
  //Artist values
  Map<String, dynamic> external_urls;
  String href;
  String id;
  String name;
  String type;
  String uri;

  ArtistSmpl({ 
    this.external_urls,
    this.href,
    this.id,
    this.name,
    this.type,
    this.uri
  });
  ArtistSmpl.fromMap(Map<String, dynamic> json) {
    this.external_urls = json['external_urls'];
    this.href = json['href'];
    this.id = json['id'];
    this.name = json['name'];
    this.type = json['type'];
    this.uri = json['uri'];
  }
}

List<ArtistSmpl> buildArtistSmplList (List<dynamic> artists) { 
  List<ArtistSmpl> artistList = new List<ArtistSmpl>();
  artists.forEach((n) { 
    ArtistSmpl artist = new ArtistSmpl.fromMap(n);
    artistList.add(artist);
  });
  return artistList;
} //Properly building list of ArtistSmpl Objects

class Image { 
  final num height;
  final String url;
  final num width;

  Image({this.height, this.url, this.width});
  Image.fromMap(Map<String, dynamic> json)
        : height = json['height'],
          url = json['url'],
          width = json['width'];
}

List<Image> buildImageList (List<dynamic> images) { 
  List<Image> imageList = new List<Image>();
  images.forEach((n) { 
    Image image = new Image.fromMap(n);
    imageList.add(image);
  });
  return imageList;
} //Properly building list of Image Objects

class LinkedTrack { 
  final Map<String, dynamic> external_urls;
  final String href;
  final String id;
  final String type;
  final String uri;
  
  LinkedTrack({ 
    this.external_urls,
    this.href,
    this.id,
    this.type,
    this.uri
  });
  LinkedTrack.fromMap(Map<String, dynamic> json)
        : external_urls = jsonDecode(json['external_urls']),
          href = json['href'],
          id = json['id'],
          type = json['type'],
          uri = json['uri'];
}