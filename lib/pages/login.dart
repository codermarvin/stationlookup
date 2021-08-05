// Flutter Technical Examination
// Marvin Aquino
// August 6, 2021

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'lookup.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  var _controllerMobile = TextEditingController();
  var _controllerPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controllerMobile.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controllerMobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mobile Number',
              ),
            ),
            Padding(padding: EdgeInsets.only(top: 8.0)),
            TextField(
              controller: _controllerPassword,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  authenticate(
                      _controllerMobile.text, _controllerPassword.text);
                },
                child: Text('Log In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void authenticate(String mobile, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://stable-api.pricelocq.com/mobile/v2/sessions';
    var data = {'mobile': mobile, 'password': password};
    try {
      var response = await http.post(Uri.parse(url), body: json.encode(data));
      if (response.statusCode == 200) {
        // Success
        var jsonResponse = json.decode(response.body);
        prefs.setString(
            'token', jsonResponse['data']['accessToken']); // Save token
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Lookup()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content:
              Text('The mobile number or password you entered is incorrect.'),
        ),
      );
    }
  }
}
