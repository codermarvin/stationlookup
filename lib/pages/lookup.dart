// Flutter Technical Examination
// Marvin Aquino
// August 6, 2021

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Lookup extends StatefulWidget {
  const Lookup({Key? key}) : super(key: key);

  @override
  _LookupState createState() => _LookupState();
}

class _LookupState extends State<Lookup> {
  final _gKey = new GlobalKey<ScaffoldState>();

  bool _showDetail = false;
  bool _doSearch = false;

  final TextEditingController _filter = new TextEditingController();
  String _searchText = '';
  List<dynamic> stations = []; // stations we get from API
  List<dynamic> filteredStations = []; // stations filtered by search text
  int _stationIndex = 0;

  late GoogleMapController _mapController;
  LatLng _userLocation = LatLng(0.0, 0.0);
  LatLng _stationLocation = LatLng(0.0, 0.0);
  double _zoomLevel = 15.0;

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
              target: _showDetail ? _stationLocation : _userLocation,
              zoom: _zoomLevel,
            ),
          ),
        );
      },
    );
  }

  Set<Marker> _createMarker() {
    return {
      Marker(
        position: _stationLocation,
        markerId: MarkerId(_stationIndex.toString()),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    };
  }

  void displayBottomSheet() async {
    if (stations.length == 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var accessToken = prefs.getString('token');
      String url = 'https://stable-api.pricelocq.com/mobile/stations?all';
      Map<String, String> header = new Map();
      header["authorization"] = "$accessToken";
      var response = await http.get(Uri.parse(url), headers: header);
      Map<String, dynamic> map = json.decode(response.body);
      stations = map['data']; // stations we get from API
      stations
        ..sort((a, b) => (Geolocator.distanceBetween(
                    _userLocation.latitude,
                    _userLocation.longitude,
                    double.parse(a['lat']),
                    double.parse(a['lng'])) ~/
                1000)
            .compareTo(Geolocator.distanceBetween(
                    _userLocation.latitude,
                    _userLocation.longitude,
                    double.parse(b['lat']),
                    double.parse(b['lng'])) ~/
                1000));
      filteredStations = stations; // stations filtered by search text
    }
    if (_searchText.isNotEmpty) {
      List<dynamic> tempList = [];
      for (int i = 0; i < filteredStations.length; i++) {
        if (filteredStations[i]['name']
            .toLowerCase()
            .contains(_searchText.toLowerCase())) {
          tempList.add(filteredStations[i]);
        }
      }
      filteredStations = tempList;
    }
    _gKey.currentState?.showBottomSheet(
      (context) {
        return _showDetail
            ? Container(
                height: MediaQuery.of(context).size.height * 0.25,
                width: double.infinity,
                padding: EdgeInsets.only(left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showDetail = false;
                            });
                          },
                          child: Text(
                            'Back to list',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter.clear();
                              _searchText = '';
                              filteredStations = stations;
                              _stationIndex = 0;
                              _doSearch = false;
                              _showDetail = false;
                            });
                          },
                          child: Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            filteredStations[_stationIndex]['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            filteredStations[_stationIndex]['address'],
                          ),
                          Text(''),
                          Row(
                            children: <Widget>[
                              Icon(Icons.directions_car_outlined),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: 5.0, right: 20.0),
                                child: Text(
                                    '${Geolocator.distanceBetween(_userLocation.latitude, _userLocation.longitude, double.parse(filteredStations[_stationIndex]['lat']), double.parse(filteredStations[_stationIndex]['lng'])) ~/ 1000} km away'),
                              ),
                              Icon(Icons.access_time),
                              Padding(
                                padding: EdgeInsets.only(left: 5.0),
                                child: Text('Open 24 hours'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            : Container(
                height: MediaQuery.of(context).size.height *
                    (_doSearch ? 1.0 : 0.4),
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                width: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  children: <Widget>[
                    _doSearch
                        ? SizedBox.shrink()
                        : Container(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Nearby Stations',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Done',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return Divider();
                        },
                        itemCount: filteredStations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              setState(
                                () {
                                  _stationIndex = index;
                                  _stationLocation = LatLng(
                                      double.parse(
                                          filteredStations[index]['lat']),
                                      double.parse(
                                          filteredStations[index]['lng']));
                                  _showDetail = true;
                                },
                              );
                            },
                            title: Text(filteredStations[index]['name']),
                            subtitle: Text(
                                '${Geolocator.distanceBetween(_userLocation.latitude, _userLocation.longitude, double.parse(filteredStations[index]['lat']), double.parse(filteredStations[index]['lng'])) ~/ 1000} km away from you'),
                            trailing: Radio<int>(
                              groupValue: _stationIndex,
                              value: index,
                              onChanged: (int? value) {
                                setState(
                                  () {
                                    _stationIndex = index;
                                    _stationLocation = LatLng(
                                      double.parse(
                                          filteredStations[index]['lat']),
                                      double.parse(
                                          filteredStations[index]['lng']),
                                    );
                                    _showDetail = true;
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
    displayBottomSheet();
    _updateCamera();

    return Scaffold(
      key: _gKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Search Station'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_doSearch ? 80 : 40),
          child: Column(children: <Widget>[
            Text('Which PriceLOCQ station will you likely to visit?',
                style: TextStyle(color: Colors.white)),
            _doSearch
                ? Container(
                    padding: EdgeInsets.only(
                        left: 50.0, top: 10.0, right: 50.0, bottom: 20.0),
                    child: TextField(
                      controller: _filter,
                      onChanged: (String value) {
                        if (_filter.text.isEmpty) {
                          setState(() {
                            _searchText = '';
                            filteredStations = stations;
                          });
                        } else {
                          setState(() {
                            _searchText = _filter.text;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  )
                : Text(''),
          ]),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _filter.clear();
                _searchText = '';
                filteredStations = stations;
                _stationIndex = 0;
                _doSearch = !_doSearch;
                _showDetail = false;
              });
            },
            icon: _doSearch ? Icon(Icons.close) : Icon(Icons.search),
          )
        ],
      ),
      body: GoogleMap(
        myLocationEnabled: true,
        markers: _createMarker(),
        initialCameraPosition: CameraPosition(
          target: _userLocation,
          zoom: _zoomLevel,
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
