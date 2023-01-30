import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps/screens/live_location_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationPermission? locationPermission;
  Position? currentPosition;    // get it when open the map for first time
  List<Placemark>? placeMarks;
  GoogleMapController? googleMapController;
  bool? locationPermissionStatus ;
  Set<Marker> markers = {};
  static LatLng cairoLatLng = const LatLng(30.033333,31.233334);
  static Marker cairoMarker = Marker(
      markerId: MarkerId("${cairoLatLng.latitude}"),
      position: cairoLatLng,
      infoWindow: const InfoWindow(title: "Cairo"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
  );
  static LatLng englandLatLng = const LatLng(53.483959,-2.244644);
  static Marker englandMarker = Marker(
      markerId: MarkerId("${englandLatLng.latitude}"),
      position: englandLatLng,
      infoWindow: const InfoWindow(title: "England"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta)
  );

  // Todo: request for permission to get The location for User && add current_location to markers
  void getLocationPermission() async {
    await Geolocator.requestPermission();
    locationPermission = await Geolocator.checkPermission();
    locationPermissionStatus = await Geolocator.isLocationServiceEnabled();
    debugPrint("Permission status is $locationPermissionStatus");
    if( locationPermissionStatus == true )
      {
        currentPosition =  await Geolocator.getCurrentPosition();
        placeMarks = await placemarkFromCoordinates(currentPosition!.latitude, currentPosition!.longitude);
        // Todo: to add my current position to markers and it will clear after click on any position on The Map
        setState(() {
          markers.add(
              Marker(
                  markerId: MarkerId("${currentPosition!.latitude}"),
                  position: LatLng(currentPosition!.latitude,currentPosition!.longitude),
                  infoWindow: InfoWindow(title: placeMarks!.first.name),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
              )
          );
        });
        debugPrint("CurrentPosition is ${currentPosition!.latitude}");
      }
    else
    {
      locationPermission = await Geolocator.requestPermission();
    }
  }

  @override
  void initState(){
    getLocationPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
            title: const Text("Google Maps"),
            actions: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=> LiveLocationScreen()));},
                child: const Icon(Icons.maps_ugc),
              ),
              )]),
        body: Column(
          children:
          [
            locationPermissionStatus == true && currentPosition != null?
            Expanded(
                child: GoogleMap(
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    markers: markers,
                    onMapCreated: (GoogleMapController controller){
                      setState(() {
                        googleMapController = controller;
                      });
                    },
                    initialCameraPosition: CameraPosition(
                        target: LatLng(currentPosition!.latitude,currentPosition!.longitude),
                        zoom: 10
                    ),
                    onTap: (LatLng latlng) async {
                      placeMarks = await placemarkFromCoordinates(latlng.latitude, latlng.longitude);
                      setState(() {
                        markers.clear();     // Todo: remove all markers to show only on the I am in its position
                        markers.add(
                            Marker(
                              markerId: MarkerId(latlng.latitude.toString()),
                              position: latlng,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                              infoWindow: InfoWindow(title: "${placeMarks!.last.street}, ${placeMarks!.last.administrativeArea}, ${placeMarks!.last.country}"),
                        ));
                      });
                    },
                )
            ) :
            const Expanded(child: Center(child: CupertinoActivityIndicator(color: Colors.purple,),)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 15),
              child: Row(
                children:
                [
                  Expanded(
                    child: buttonItem(latLng: englandLatLng, placeTitle: "England"),
                  ),
                  const SizedBox(width: 15,),
                  Expanded(
                    child: buttonItem(latLng: cairoLatLng, placeTitle: "Cairo"),
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }

  Widget buttonItem({required LatLng latLng,required String placeTitle}){
    return MaterialButton(
      onPressed: ()
      {
        setState(() {
          placeTitle == "Cairo" ? markers.add(cairoMarker) : markers.add(englandMarker);
        });
        googleMapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng,zoom: 14)));
      },
      color: Colors.purple,
      child: Text(placeTitle,style: const TextStyle(color: Colors.white),),
    );
  }
}
