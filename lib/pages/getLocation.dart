class Place{
  final String placeId;
  final String description;


  Place({ this.placeId,this.description});

  factory Place.fromJson(Map<String,dynamic> json){
    return Place(
      placeId: json["place_id"],
      description: json["description"],

    );
  }
}
