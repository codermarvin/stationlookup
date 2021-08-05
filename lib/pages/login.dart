import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'landing.dart';

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
      body: Column(
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
          TextField(
            controller: _controllerPassword,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Password',
            ),
          ),
          ElevatedButton(
              onPressed: () {
                authenticate(_controllerMobile.text, _controllerPassword.text);
              },
              child: Text('Log In')),
        ],
      ),
    );
  }

  void authenticate(String mobile, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String url = 'https://stable-api.pricelocq.com/mobile/v2/sessions';
    var data = {'mobile': mobile, 'password': password};
    var response = await http.post(Uri.parse(url), body: json.encode(data));
    if (response.statusCode == 200) {
      // Success
      var jsonResponse = json.decode(response.body);
      prefs.setString(
          'token', jsonResponse['data']['accessToken']); // Save token
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Landing()),
      );
    }
  }
}
