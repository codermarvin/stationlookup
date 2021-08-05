import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Landing extends StatefulWidget {
  const Landing({Key? key}) : super(key: key);

  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  late GoogleMapController _mapController;
  late LatLng _userLocation;

  Future<Position> _getLocation() async {
    var currentLocation;
    try {
      currentLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      currentLocation = null;
    }
    return currentLocation;
  }

  Future<void> _updateCamera() async {
    await Future.delayed(Duration(seconds: 2)).then(
      (_) {
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _userLocation,
              zoom: 15,
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _getLocation().then((position) {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Search Station'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Text('Which PriceLOCQ station will you likely to visit?',
              style: TextStyle(color: Colors.white)),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
          )
        ],
      ),
      body: GoogleMap(
        myLocationEnabled: true,
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 15,
        ),
        onMapCreated: (controller) async {
          setState(() {
            _mapController = controller;
          });
          _updateCamera();
        },
      ),
    );
  }
}
