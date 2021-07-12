import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:taxi/pages/getLocation.dart';
import 'package:uuid/uuid.dart';

  class placeService{
  final key = "API_KEY";
  final sessionToken = Uuid().v4();

  Future<List<Place>> getAutoComplete(String search) async{
    var url ='https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$search&types=(region)&language=en&components=country:in&key=$key&sessiontoken=$sessionToken';
    var response = await http.get(Uri.parse(url),headers: {'Content-type' : 'application/json'});
    if (response.statusCode == 200) {
      final result = convert.jsonDecode(response.body);
      if (result['status'] == 'OK') {
        var res = result['predictions'] as List;
        return res.map((p) => Place.fromJson(p)).toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
    var json = convert.jsonDecode(response.body);
    print(json);
    var results = json['predictions'] as List;
    return results.map((p) => Place.fromJson(p)).toList();
  }
}