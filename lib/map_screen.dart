import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:multiple_polyline_demo/map_style.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  final Logger _logger = Logger();
  CameraPosition _kGoogle = const CameraPosition(
    target: LatLng(19.0759837,
        72.8776559), // Default location in case location access is denied
    zoom: 15,
  );
  String? _currentAddress;
  Position? _currentPosition;

  List<String> images = [
    'assets/gym.png',
    'assets/cinema.png',
    'assets/patrol.png',
    'assets/caffe.png',
    'assets/gym.png'
  ];

  final List<Marker> _markers = <Marker>[];
  final List<LatLng> _latLen = <LatLng>[
    LatLng(19.0759837, 72.8776559),
    LatLng(28.679079, 77.069710),
    LatLng(26.850000, 80.949997),
    LatLng(24.879999, 74.629997),
    LatLng(16.166700, 74.833298),
    LatLng(12.971599, 77.594563),
  ];

  double _currentZoom = 15.0;

  Future<Uint8List> getImages(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetHeight: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  void initState() {
    super.initState();
    loadData(_currentZoom);
    _getCurrentPosition();
  }

  loadData(double zoom) async {
    int size = (100 - (zoom * 5))
        .toInt()
        .clamp(30, 100); // Inverted size based on zoom level
    _markers.clear(); // Clear existing markers before adding new ones

    for (int i = 0; i < images.length; i++) {
      final Uint8List markIcons = await getImages(images[i], size);
      _markers.add(Marker(
        markerId: MarkerId(i.toString()),
        icon: BitmapDescriptor.bytes(markIcons),
        position: _latLen[i],
        consumeTapEvents: false,
        infoWindow: InfoWindow(
          title: 'Location: ' + i.toString(),
        ),
      ));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0F9D58),
        title: Text("Map"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kGoogle,
            markers: Set<Marker>.of(_markers),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: false,
            style: Utils.mapStyle,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (position) {
              double newZoom = position.zoom;
              if (_currentZoom != newZoom) {
                _currentZoom = newZoom;
                loadData(
                    _currentZoom); // Update marker size based on zoom level
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      _logger.w('Location permission denied.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        // Update the camera position to the current location
        _kGoogle = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
        );
        _markers.add(Marker(
          markerId: MarkerId('current_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueMagenta, // Customize the marker color
          ),
          consumeTapEvents: false,
          infoWindow: InfoWindow(
            title: 'You are here',
          ),
        ));
      });

      // Move the camera to the user's current location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_kGoogle));

      _logger.i('Current position: $_currentPosition');
    } catch (e, stackTrace) {
      _logger.e('Failed to get current position${e.toString()}');
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }
}
