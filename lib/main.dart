import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(LocationApp());
}

class LocationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LocationInputScreen(),
    );
  }
}

class LocationInputScreen extends StatefulWidget {
  @override
  _LocationInputScreenState createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  void _validateAndNavigate(BuildContext context) async {
    final inputLocation = _controller.text.trim();
    if (inputLocation.isEmpty) {
      setState(() {
        _errorText = 'Please enter a valid location';
      });
    } else {
      try {
        final locationData = await getLocationFromApi(inputLocation);
        if (locationData != null &&
            locationData['lat'] != null &&
            locationData['lng'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(
                latitude: locationData['lat']!,
                longitude: locationData['lng']!,
                locationName: inputLocation,
                fullAddress: locationData['full_address']!,
              ),
            ),
          );
        } else {
          setState(() {
            _errorText = 'No locations found. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorText =
          'Could not find location: ${e.toString()}. Please try again.';
        });
      }
    }
  }

  Future<Map<String, dynamic>?> getLocationFromApi(String address) async {
    final apiKey = 'Enter Your API';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        final fullAddress = data['results'][0]['formatted_address'];
        return {
          'lat': location['lat'],
          'lng': location['lng'],
          'full_address': fullAddress,
        };
      }
    } else {
      throw Exception('Failed to load location');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Location')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a location (City, Address)',
                errorText: _errorText,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _validateAndNavigate(context),
              child: Text('Show on Map'),
            ),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final String fullAddress;

  const MapScreen({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.fullAddress,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  LatLng _initialPosition = LatLng(0, 0);
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _initialPosition = LatLng(widget.latitude, widget.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
      _isMapLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 16.0,
            ),
            onMapCreated: _onMapCreated,
            markers: {
              Marker(
                markerId: MarkerId(widget.locationName),
                position: _initialPosition,
                infoWindow: InfoWindow(title: widget.locationName),
              ),
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(15),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fullAddress,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                    },
                    child: Text("Tap to show more result options"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
