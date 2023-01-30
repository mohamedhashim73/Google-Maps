import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({Key? key}) : super(key: key);

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  LocationPermission? locationPermission;
  bool? locationPermissionStatus ;
  StreamSubscription<Position>? positionStream;
  Position? currentPosition;
  double distanceBetweenCurrentAndTarget = 0;
  static GoogleMapController? googleMapController;
  // Todo: I will draw a polyline between my current position and Cairo's position
  static double currentLatitude = 0;
  static double currentLongitude = 0 ;
  static LatLng targetLatLng = const LatLng(30.7911111,30.9980556);
  static List<LatLng> pointsLatLng = [targetLatLng];

  Set<Polyline> polyLines = {
    Polyline(
        polylineId: PolylineId(targetLatLng.latitude.toString()),
        points: pointsLatLng,
        patterns: [PatternItem.dot,PatternItem.gap(12.5)]
    ),
  };

  static Set<Marker> markers = {
    Marker(markerId: const MarkerId("target_position"),position: targetLatLng,icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),infoWindow: const InfoWindow(title: "Cairo")),
  };

  void checkLocationPermission() async {
    await Geolocator.requestPermission();
    locationPermission = await Geolocator.checkPermission();
    locationPermissionStatus = await Geolocator.isLocationServiceEnabled();
    setState(() {});
    debugPrint("Location permission status is $locationPermissionStatus");
    if( locationPermissionStatus == false )
      {
        await Geolocator.requestPermission();
      }
  }

  @override
  void initState() {
    checkLocationPermission();
    setState(() {
      positionStream = Geolocator.getPositionStream().listen((Position livePosition){
        distanceBetweenCurrentAndTarget = Geolocator.distanceBetween(livePosition.latitude, livePosition.longitude, targetLatLng.latitude, targetLatLng.longitude)/1000;
        if( googleMapController != null) googleMapController!.animateCamera(CameraUpdate.newLatLng(LatLng(livePosition.latitude,livePosition.longitude)));
        markers.remove(const Marker(markerId: MarkerId("current_position")));
        markers.add(Marker(
              markerId: const MarkerId("current_position"),
              position: LatLng(livePosition.latitude,livePosition.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
          ),
        );
        pointsLatLng.add(LatLng(livePosition.latitude, livePosition.longitude));
        pointsLatLng.removeAt(pointsLatLng.length-1);   // Todo: to remove the last item on list ( currentPosition )
        pointsLatLng.add(LatLng(livePosition.latitude, livePosition.longitude));
        currentPosition = livePosition;
        currentLatitude = currentPosition!.latitude;
        currentLongitude = currentPosition!.longitude;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    positionStream!.cancel();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Position"),),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
        [
          if( locationPermissionStatus == true && currentPosition != null )
          Expanded(
            child: GoogleMap(
              polylines: polyLines,
              onMapCreated: (mapController){
                setState(()
                {
                  googleMapController = mapController;
                });
              },
              markers: markers,
              initialCameraPosition: CameraPosition(target: LatLng(currentPosition!.latitude,currentPosition!.longitude),zoom: 8),
              mapType: MapType.normal,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0,vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
              [
                if( currentPosition != null )
                  Text.rich(
                      TextSpan(
                          children:
                          [
                            const TextSpan(text: "current latitude equal  ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500)),
                            TextSpan(text: "${currentPosition!.latitude}",style: const TextStyle(color: Colors.purple,fontWeight: FontWeight.bold,fontSize: 17)),
                          ]
                      )
                  ),
                const SizedBox(height: 10,),
                if( currentPosition != null )
                  Text.rich(
                      TextSpan(
                          children:
                          [
                            const TextSpan(text: "current longitude equal  ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500)),
                            TextSpan(text: "${currentPosition!.longitude}",style: const TextStyle(color: Colors.purple,fontWeight: FontWeight.bold,fontSize: 17)),
                          ]
                      )
                  ),
                const SizedBox(height: 10,),
                Text.rich(
                    TextSpan(
                        children:
                        [
                          const TextSpan(text: "DistanceBetweenCurrentAndTarget is ",style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500)),
                          TextSpan(text: "${distanceBetweenCurrentAndTarget.toStringAsPrecision(4)} km",style: const TextStyle(color: Colors.purple,fontWeight: FontWeight.bold,fontSize: 17)),
                        ]
                    )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
