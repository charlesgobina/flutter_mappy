import 'dart:async';
import 'dart:math';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mappy/features/maps/services/distance_service.dart';

class Mappy extends StatefulWidget {
  const Mappy({super.key});

  @override
  State<Mappy> createState() => MappyState();
}

class MappyState extends State<Mappy> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  late Position _currentPosition = Position(
      longitude: -122.085749655962,
      latitude: 37.42796133580664,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);
  final Map<String, Marker> _markers = {};
  bool isDestinationSet = false;
  final TextEditingController _destinationController = TextEditingController();
  late Location? _destinationLocation = Location(latitude: 0, longitude: 0, timestamp: DateTime.now());
  Future<List<Location>> getLocationLatLng(String address) async {
    List<Location> locations = await locationFromAddress(address);
    return locations;
  }

  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = "AIzaSyDJu89H8BuFgVRPmlEAEhO4RJ8ym7Wf85I";

  // static const CameraPosition _kGooglePlex = CameraPosition(
  //   target: LatLng(37.42796133580664, -122.085749655962),
  //   zoom: 14.4746,
  // );

  // static final Marker _currentLocationMarker = Marker(
  //   markerId: const MarkerId('_currentLocationMarker'),
  //   position: const LatLng(37.42796133580664, -122.085749655962),
  //   infoWindow: const InfoWindow(
  //     title: 'Marker Title',
  //     snippet: 'Marker Snippet',
  //   ),
  //   icon: BitmapDescriptor.defaultMarker,
  //   onTap: () {
  //     print('Marker Tapped');
  //   },
  // );

  // static final Marker _kLakeMarker = Marker(
  //   markerId: const MarkerId('_kLakeMarker'),
  //   position: const LatLng(37.43296265331129, -122.08832357078792),
  //   infoWindow: const InfoWindow(
  //     title: 'Lake Area',
  //     snippet: 'Lake Area Snippet',
  //   ),
  //   icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
  //   onTap: () {
  //     print('Marker Tapped');
  //   },
  // );

  // get current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permantly denied, we cannot request permissions.');
      }
    }
    Position position = await Geolocator.getCurrentPosition();
    return position;
  }

  // function to return distance betweeb two points
  double getDistance(
      {double? latitude1,
      double? latitude2,
      double? longitude1,
      double? longitude2}) {
    Haversine distanceService = Haversine(
        latitude1: latitude1,
        latitude2: latitude2,
        longitude1: longitude1,
        longitude2: longitude2);
    double distance = distanceService.distance();
    return distance;
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation().then((value) {
      setState(() {
        _currentPosition = value;
      });
    });
    goToPlace(LatLng(_currentPosition.latitude, _currentPosition.longitude));
  }

  @override
  Widget build(BuildContext context) {
    double distance = getDistance(
              latitude1: _currentPosition.latitude,
              latitude2: _destinationLocation!.latitude,
              longitude1: _currentPosition.longitude,
              longitude2: _destinationLocation!.longitude);
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _destinationController,
                    style: const TextStyle(
                        fontSize: 18,
                        leadingDistribution: TextLeadingDistribution.even),
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      hintText: 'Enter your destination location',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // search icon
                IconButton(
                  onPressed: () async {
                    List<Location> locations =
                        await getLocationLatLng(_destinationController.text);
                    setState(() {
                      _destinationLocation = locations[0];
                      isDestinationSet = true;
                    });
                    await Future.delayed(const Duration(seconds: 5));
                    getPolyline();
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            isDestinationSet ?
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                  child: Text('$distance Meters'),
                ),
              ],
            ): Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                  child: Text('0 Meters', 
                  style: TextStyle(color: Color.fromARGB(255, 175, 175, 175)),),
                ),
              ],
            ),
            
            Expanded(
              child: GoogleMap(
                markers: _markers.values.toSet(),
                polylines: Set<Polyline>.of(polylines.values),
                mapType: MapType.normal,
                initialCameraPosition: initialCameraPositiony(LatLng(
                    _currentPosition.latitude, _currentPosition.longitude)),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  addMarker(
                      '_currentLocationMarker',
                      LatLng(_currentPosition.latitude,
                          _currentPosition.longitude));
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            addMarker('_currentLocationMarker',
                LatLng(_currentPosition.latitude, _currentPosition.longitude));
            goToPlace(
                LatLng(_currentPosition.latitude, _currentPosition.longitude));
          },
          label: const Text('Find me!'),
          icon: const Icon(Icons.directions_walk),
        ),
      ),
    );
  }

  goToPlace(LatLng latLng) async {
    final GoogleMapController controller = await _controller.future;
    return controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: latLng,
      zoom: 16.4746,
    )));
  }

  CameraPosition initialCameraPositiony(LatLng latLng) {
    return CameraPosition(
      target: latLng,
      zoom: 18.4746,
    );
  }

  // add marker
  addMarker(String id, LatLng latLng) {
    Marker marker = Marker(
      markerId: MarkerId(id),
      position: latLng,
    );
    _markers[id] = marker;
    setState(() {});
  }

  addPolyline() {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: const Color.fromARGB(255, 0, 52, 142),
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  // add polyline
  getPolyline() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleAPiKey,
      PointLatLng(_currentPosition.latitude, _currentPosition.longitude),
      PointLatLng(
          _destinationLocation!.latitude, _destinationLocation!.longitude),
      travelMode: TravelMode.walking,
    );

    // random number generator
    var rng = Random();
    int randomNumber = rng.nextInt(100000000);
    addMarker('marker-$randomNumber',
        LatLng(_destinationLocation!.latitude, _destinationLocation!.longitude));

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    addPolyline();
  }
}
