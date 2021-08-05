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
  int _groupValue = 0;

  late GoogleMapController _mapController;
  late LatLng _userLocation;

  bool stationDetail = false;
  bool startSearch = false;
  var _search = TextEditingController();

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

  void displayBottomSheet() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('token');
    String url = 'https://stable-api.pricelocq.com/mobile/stations?all';
    Map<String, String> header = new Map();
    header["authorization"] = "$accessToken";
    var response = await http.get(Uri.parse(url), headers: header);
    Map<String, dynamic> map = json.decode(response.body);
    List<dynamic> _stations = map['data'];
    _gKey.currentState?.showBottomSheet(
      (context) {
        return stationDetail && !startSearch
            ? Container(
                height: 200,
                width: double.infinity,
                padding: EdgeInsets.only(left: 20.0, top: 10.0, right: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              stationDetail = false;
                            });
                          },
                          child: Text('Back to list'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text('Done'),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Address 1'),
                          Text('Address 2'),
                          Text(''),
                          Row(
                            children: <Widget>[
                              Icon(Icons.directions_car_outlined),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: 5.0, right: 20.0),
                                child: Text('1 km away'),
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
                height: startSearch ? 600 : 300,
                padding: EdgeInsets.only(left: 8.0, right: 8.0),
                width: double.infinity,
                alignment: Alignment.center,
                child: Column(
                  children: <Widget>[
                    startSearch
                        ? SizedBox.shrink()
                        : Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                TextButton(
                                  onPressed: () {},
                                  child: Text('Nearby Stations'),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text('Done'),
                                ),
                              ],
                            ),
                          ),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) {
                          return Divider();
                        },
                        itemCount: _stations.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              setState(() {
                                _groupValue = index;
                                stationDetail = true;
                                startSearch = false;
                              });
                            },
                            title: Text(_stations[index]['name']),
                            subtitle: Text('1km away from you'),
                            trailing: Radio<int>(
                              groupValue: _groupValue,
                              value: index,
                              onChanged: (int? value) {
                                setState(() {
                                  _groupValue = index;
                                  stationDetail = true;
                                  startSearch = false;
                                });
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

    return Scaffold(
      key: _gKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Search Station'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(startSearch ? 80 : 40),
          child: Column(children: <Widget>[
            Text('Which PriceLOCQ station will you likely to visit?',
                style: TextStyle(color: Colors.white)),
            startSearch
                ? Container(
                    padding: EdgeInsets.only(
                        left: 50.0, top: 10.0, right: 50.0, bottom: 20.0),
                    child: TextField(
                      controller: _search,
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
                startSearch = !startSearch;
              });
            },
            icon: startSearch ? Icon(Icons.close) : Icon(Icons.search),
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
