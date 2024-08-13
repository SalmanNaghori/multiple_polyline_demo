import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final LatLngBounds? bounds;
  final List<PointLatLng>? polylinePoints;
  final String? totalDistance;
  final String? totalDuration;
  final String? alternativeTotalDistance;
  final String? alternativeTotalDuration;
  final List<PointLatLng>? alternativePolylinePoints;

  const Directions({
    required this.alternativePolylinePoints,
    required this.alternativeTotalDistance,
    required this.alternativeTotalDuration,
    required this.bounds,
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
  });

  // Making the return type nullable by using `Directions?`
  factory Directions.fromMap(Map<String, dynamic> map) {
    // Check if route is not available
    // if ((map['routes'] as List).isEmpty) return null;

    final data = Map<String, dynamic>.from(map['routes'][0]);

    // Bounds
    final northeast = data['bounds']['northeast'];
    final southwest = data['bounds']['southwest'];
    final bounds = LatLngBounds(
      southwest: LatLng(southwest['lat'], southwest['lng']),
      northeast: LatLng(northeast['lat'], northeast['lng']),
    );

    // Distance & duration
    String distance = '';
    String duration = '';
    if ((data['legs'] as List).isNotEmpty) {
      final leg = data['legs'][0];
      distance = leg['distance']['text'];
      duration = leg['duration']['text'];
    }

    // Alternative route
    List<PointLatLng>? alternativeRoutePolyLinePoints;
    String? alternativeDistance;
    String? alternativeDuration;

    if ((map['routes'] as List).length > 1) {
      final alternativeRoute = Map<String, dynamic>.from(map['routes'][1]);
      alternativeRoutePolyLinePoints = PolylinePoints()
          .decodePolyline(alternativeRoute['overview_polyline']['points']);
      alternativeDuration = alternativeRoute['legs'][0]['duration']['text'];
      alternativeDistance = alternativeRoute['legs'][0]['distance']['text'];
    }

    return Directions(
      alternativePolylinePoints: alternativeRoutePolyLinePoints,
      alternativeTotalDistance: alternativeDistance,
      alternativeTotalDuration: alternativeDuration,
      bounds: bounds,
      polylinePoints:
          PolylinePoints().decodePolyline(data['overview_polyline']['points']),
      totalDistance: distance,
      totalDuration: duration,
    );
  }
}
