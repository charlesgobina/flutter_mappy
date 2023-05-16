import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationServices{
  String key = 'AIzaSyDJu89H8BuFgVRPmlEAEhO4RJ8ym7Wf85I';

  Future<String> getPlaceId(String placeName) async {
    String url = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName&inputtype=textquery&fields=place_id&key=$key';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('success');
      var json = jsonDecode(response.body);
      print(json);
      // var placeId = json['candidates'][0]['place_id'];
      // print(placeId);
      return json as String;
    } else {
      throw Exception('Failed to load place id');
    }
  }

}