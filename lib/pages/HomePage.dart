import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi/Services/PlaceService.dart';
import 'package:taxi/Services/address_search.dart';
import 'package:taxi/Services/direction_model.dart';
import 'package:taxi/Services/direction_repositry.dart';
import 'package:taxi/Services/permission.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

import 'getLocation.dart';


const double _minHeight = 230;
const double _maxHeight = 635;
const kGoogleApiKey = "API_KEY";


class HomePage extends StatefulWidget{
  @override
  _HomepageState createState() => new _HomepageState();
}

class _HomepageState extends State<HomePage>  with TickerProviderStateMixin {
  Completer<GoogleMapController> _controller = Completer();
  Position position;
  LatLng _initialPosition;
  AnimationController _animationController;
  var drag = 0;
  double _currentHeight = _minHeight;
  Marker origin;
  StreamSubscription positionStream;
  Marker destination;
  GoogleMapController controller;
  var field;
  GoogleMap googleMap;
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints;
  Directions _info;
  TextEditingController currentLocation = new TextEditingController();
  TextEditingController destinationLocation = new TextEditingController();
  var curr_address;
  FocusNode myFocusNode;
  LatLng coordinates;
  List<Place> result;

  // LatLng _lastPosition = _initialPosition;

  final Set<Marker> _markers = {
  };

  static final CameraPosition cameraPosition = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);


  @override
  void initState() {
    // TODO: implement initState
    myFocusNode = FocusNode();
    polylinePoints = PolylinePoints();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 675),
      vsync: this,
    );
    _getCurrentLocation();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    // print(path);
    ByteData data = await rootBundle.load(path);
    // ByteData data = await path.readAsBytesSync().buffer.asByteData();
    ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer
        .asUint8List();
  }


  // Future<void> updateMarker(Position livposition, StreamSubscription positionStream) async {
  Future<void> updateMarker(String pick, String drop) async {
    controller = await _controller.future;
    List<Location> locations = await locationFromAddress(drop);
    List<Location> pickloc = await locationFromAddress(pick);
    LatLng latlng = LatLng(pickloc[0].latitude, pickloc[0].longitude);
    print(locations);
    final Uint8List markerIcon = await getBytesFromAsset(
        'assets/images/drop.jpg', 50);
    final Uint8List markerpick = await getBytesFromAsset(
        'assets/images/pick.jpg', 50);
    LatLng desti = LatLng(locations[0].latitude, locations[0].longitude);

    this.setState(() {
      origin = Marker(
        markerId: MarkerId("Your Location"),
        position: latlng,
        icon: BitmapDescriptor.fromBytes(markerpick),
        draggable: true,
        zIndex: 2,
        flat: true,
        anchor: Offset(0.5, 0.5),
      );
    });
    this.setState(() {
      destination = Marker(
        markerId: MarkerId("Destination"),
        position: desti,
        draggable: true,
        zIndex: 2,
        flat: true,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        infoWindow: InfoWindow(title: "Destination"),
        anchor: Offset(0.5, 0.5),
      );
    });

    final directions = await DirectionRepositry().getDirections(
        origin: origin.position, destination: destination.position);
    setState(() => _info = directions);
    await controller.animateCamera(
        _info != null ?
        CameraUpdate.newLatLngBounds(_info.bounds, 100.0) :
        CameraUpdate.newCameraPosition(new CameraPosition(
          bearing: 270.0,
          target: LatLng(pickloc[0].latitude, pickloc[0].longitude),
          zoom: 15,
        )
        )
    );
  }

  _getCurrentLocation() async {
    var permission = await service().checkservice();
    print(permission);
    if(permission == LocationPermission.deniedForever) {
      _showDialog();
    }
    // controller = await _controller.future;

    Position currposition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // List<Placemark> placemark = await Geolocator.placemarkFromCoordinates(currposition.latitude, currposition.longitude);

    position = currposition;
    coordinates = new LatLng(
        position.latitude, position.longitude);
    print(  LatLng(
        position.latitude, position.longitude));
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      // currentLocation.text = '${first.addressLine}';
    });
    controller = await _controller.future;

    // _onStart();
    positionStream = Geolocator.getPositionStream().listen(
            (Position livposition) async{
          coordinates = new LatLng(
              livposition.latitude, livposition.longitude);
          print(  LatLng(
              livposition.latitude, livposition.longitude));
          controller.animateCamera(
              _info!=null?
              CameraUpdate.newLatLngBounds(_info.bounds, 100.0):
              CameraUpdate.newCameraPosition(new CameraPosition(
                bearing: 270.0,
                target: LatLng(livposition.latitude, livposition.longitude),
                zoom: 15,
              )
              )
          );
          // updateMarker(livposition,positionStream);

        });

  }



  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body:
      _initialPosition != null ?
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: _minHeight),
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15,
              ),
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: {
                if(origin != null) origin,
                if(destination != null) destination,
              },
              polylines: {
                if(_info != null)
                  Polyline(
                    polylineId: PolylineId('overview_polyline'),
                    color: Colors.black,
                    width: 4,
                    points: _info.polylinePoints.
                    map((e) => LatLng(e.latitude, e.longitude)).toList(),
                  )
              },
            ),
          ),
          Positioned(
            bottom: MediaQuery
                .of(context)
                .size
                .height / 3.0,
            right: 15,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {},
              backgroundColor: Colors.white,
              child: Icon(
                Icons.gps_fixed,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              maxRadius: 22,
              child: IconButton(
                // onPressed: _ope/nDrawer,
                icon: Icon(
                  Icons.menu,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                final newHeight = _currentHeight - details.delta.dy;
                _animationController.value = _currentHeight / _maxHeight;
                _currentHeight = newHeight.clamp(0.0, _maxHeight);
              });
            },
            onVerticalDragEnd: (details) {
              if (_currentHeight < _maxHeight / 1.4) {
                setState(() {
                  _animationController.reset();
                  _currentHeight = _minHeight;
                });
              } else {
                setState(() {
                  _animationController.forward(
                      from: _currentHeight / _maxHeight);
                  _currentHeight = _maxHeight;
                });
              }
            },
            child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, snapshot) {
                  final value = _animationController.value;
                  return Stack(
                    children: [
                      Positioned(
                        height: ui.lerpDouble(_minHeight, _maxHeight, value),
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _dragwidget(),
                      ),

                    ],
                  );
                }),
          ),

          AnimatedBuilder(
            animation: _animationController,
            builder: (context, snapshot) =>
                Positioned(
                  left: 0,
                  right: 0,
                  top: -182 * (1 - _animationController.value),
                  child: Container(height: result == null?field=="pick"?230:180:450, child: mybar()),
                ),
          ),

        ],
      ) : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget mybar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.black),
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _animationController.reverse();
            _currentHeight = 0.0;
            FocusScope.of(context).unfocus();
          });
        },
      ),
      bottom: PreferredSize(
        child:
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 21.5),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.person_pin, size: 19, color: Colors.black),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Container(
                      height: 40,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width / 1.4,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(left: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: Colors.grey[200],
                      ),
                      child: TextField(
                        controller: currentLocation,
                        onTap: (){
                          setState(() {
                            field = "pick";
                          });
                        },
                        enabled: true,
                        onChanged: (value){
                          application().searchPlaces(value).then((val){
                            setState(() {
                              field = "pick";
                              result= val;
                            });
                          });
                        },
                        autofocus: false,
                        decoration: InputDecoration.collapsed(
                            hintText: ' Your current location',
                            hintStyle: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 9,
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_city, size: 19, color: Colors.black),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Container(
                          height: 40,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width / 1.4,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.only(left: 10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6.0),
                            color: Colors.grey[200],
                          ),
                          child: TextField(
                            controller: destinationLocation,
                            onTap: ()  {
                              setState(() {
                                field = "drop";
                              });
                            },
                            enabled: true,
                            onChanged: (val){
                              application().searchPlaces(val).then((val){
                                setState(() {
                                  field = "drop";
                                  result= val;
                                });
                              });
                            },
                            // autofocus: focus,
                            focusNode: myFocusNode,
                            decoration: InputDecoration.collapsed(
                                hintText: ' Enter destination ',
                                hintStyle: TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )
                    ],
                  ),
                  InkWell(
                    child: Icon(
                      Icons.add,
                      size: 25,
                    ),
                    onTap: () async {
                      updateMarker(
                          currentLocation.text, destinationLocation.text);
                      _animationController.reverse();
                      _currentHeight = 0.0;
                      setState(() {
                        drag = 1;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 10.0,
              ),
              field == "pick"?Padding(
                  padding:EdgeInsets.all(10),
                  child: InkWell(
                      onTap: () async {
                        print(coordinates);
                        final coor = new Coordinates(coordinates.latitude, coordinates.longitude);
                        var addresses = await Geocoder.local.findAddressesFromCoordinates(
                            coor);
                        var first = addresses.first;
                        currentLocation.text = first.addressLine;
                      },
                      child: Row(
                        children: [
                          Icon(Icons.location_pin,
                            size:20,
                            color:Colors.black,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child: Text("Set Current Location",
                                style:TextStyle(
                                    fontSize: 16,
                                    fontWeight:FontWeight.w500
                                )
                            ),
                          )
                        ],
                      )
                  )

              ):Container(),
              result != null?Container(
                height:230,
                child: ListView.builder(
                  itemCount:result.length,
                  itemBuilder: (context,index){
                    return ListTile(
                      title:Text(result[index].description),
                      onTap: (){
                        field == "drop"?destinationLocation.text=result[index].description:currentLocation.text=result[index].description;
                        updateMarker(
                            currentLocation.text, destinationLocation.text);
                        _animationController.reverse();
                        _currentHeight = 0.0;
                        setState(() {
                          result=null;
                          drag = 1;
                        });
                        FocusScope.of(context).unfocus();
                      },
                    );
                  },
                ),
              ):Container()
            ],
          ),
        ),

        preferredSize: Size.fromHeight(80.0),
      ),
    );
  }

  Widget _dragwidget() {
    return Container(
      //height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(0, -1),
              blurRadius: 3,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10.0),
              width: 35,
              color: Colors.grey[300],
              height: 3.5,
            ),

            drag == 0 ? searchfield() : confirmField(),
            // searchfield(),
            drag == 0 ? _savedplace() : Container(),
            // _savedplace() ,
          ],
        ));
  }

  Widget searchfield() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _animationController.forward(from: _currentHeight / _maxHeight);
          _currentHeight = _maxHeight;
          FocusScope.of(context).requestFocus(myFocusNode);
        });
      },
      child: Container(
        height: 50,
        width: MediaQuery
            .of(context)
            .size
            .width / 1.1,
        alignment: Alignment.center,
        padding: EdgeInsets.only(left: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Colors.grey[200],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Padding(
              padding: const EdgeInsets.only(right: 30.0),
              child: Text(
                ' Enter pickup point? ',
                style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9,),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(33)
                ),
                child: OutlineButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.access_time_rounded, color: Colors.black,),
                  highlightElevation: 2,
                  label: Text("Now"),
                  shape: StadiumBorder(),
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget confirmField() {
    return GestureDetector(
      onTap: () {

      },
      child: Container(
        height: 190,
        // width: MediaQuery.of(context).size.width / 1.1,
        alignment: Alignment.center,
        padding: EdgeInsets.only(left: 10.0),
        decoration: BoxDecoration(
            border: Border(
            )
        ),
        child: Column(
          children: [
            Center(
              child: Text(
                "Choose a ride",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15
                ),
              ),
            ),
            Expanded(
              child:
              ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    ListTile(
                      leading: SizedBox(
                          height: 60.0,
                          width: 60.0, // fixed width and height
                          child: Image.asset("assets/images/auto.jpg")
                      ),
                      title: Text('Uber Auto',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )
                      ),
                      trailing: Text("\$ 123",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    ListTile(
                      leading: SizedBox(
                          height: 50.0,
                          width: 50.0, // fixed width and height
                          child: Image.asset("assets/images/car.jpg")
                      ),
                      title: Text('  Uber Prime',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )),
                      trailing: Text("\$ 200", style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                  ]
              ),

            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 40.0, right: 40, top: 15, bottom: 15),
                        child: Text(
                            "Confirm Ride",
                            style: TextStyle(fontSize: 14)
                        ),
                      ),
                      style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all<Color>(
                              Colors.white),
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.black),
                          shape: MaterialStateProperty.all<
                              RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.black)
                              )
                          )
                      ),
                      onPressed: () => null
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: ElevatedButton(
                        child: Text(
                            "Cancel",
                            style: TextStyle(fontSize: 14)
                        ),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Colors.black),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.white),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.white)
                                )
                            )
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()),
                          );
                        }
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Permission Denied'),
          content: Text('Please allow location service in app setttings'),
          actions: [
            FlatButton(
              child: Text(
                "OK",
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              onPressed: () async {
                await service().checkservice();
                Navigator.pop(context);
              },
            ),
          ],
        )
    );
  }

}

Widget _savedplace(){
  return InkWell(
    child: Padding(
      padding: EdgeInsets.all(22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.black12,
                child: Icon(Icons.star,size: 17,color: Colors.black,),
              ),
              Padding(
                padding: const EdgeInsets.only(left:18.0,right: 18),
                child: Text(
                  "Saved Places",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),

                ),
              ),

            ],
          ),
          Icon(Icons.arrow_forward_ios,size: 15,color: Colors.black,),
        ],
      ),
    ),
  );
}

class application with ChangeNotifier{
  final placesService = placeService();
  List<Place> searchresults;
  searchPlaces(String s) async{
    searchresults = await placesService.getAutoComplete(s);
    notifyListeners();
    return searchresults;
  }
}

