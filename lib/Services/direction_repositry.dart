import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'direction_model.dart';

class DirectionRepositry{
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json?';

  final Dio dio;

  DirectionRepositry({Dio dio}) : dio=dio ?? Dio();

  Future<Directions> getDirections({
    @required LatLng origin,
    @required LatLng destination,
  })async{
    final response = await dio.get(
        _baseUrl,
        queryParameters: {
          'origin':'${origin.latitude},${origin.longitude}',
          'destination':'${destination.latitude},${destination.longitude}',
          'key':"AIzaSyA1fCASJErNUjWPPhCrXofo9WRgFNy8f5Q",
        }
    );
    if(response.statusCode ==200){
      return Directions.fromMap(response.data);
    }
    return null;
  }
}
