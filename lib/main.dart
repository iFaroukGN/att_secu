import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() => runApp(VulnerableApp());

class VulnerableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Vulnérable',
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatelessWidget {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void login(BuildContext context) async {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:3001/login"),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
      },
      body: {
        'username': usernameController.text,
        'password': passwordController.text,
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['success']) {
        // final token = 'vulnerable_secret_key';
        final token = result['token'];
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Dashboard(username: usernameController.text, token: token)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Échec de connexion")));
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Erreur réseau"),
          content: Text("Code: ${response.statusCode}, Body: ${response.body}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Nom d\'utilisateur')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: false),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => login(context), child: Text('Se connecter')),
          ],
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final String username;
  final String token;
  Dashboard({required this.username, required this.token});

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:3001/profile"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'error': 'Erreur lors de la récupération du profil'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tableau de bord')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Erreur de chargement'));
          } else {
            final profile = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Bienvenue $username!'),
                  SizedBox(height: 10),
                  // Text('Email: \${profile['email']}'),
                  // Text('Rôle: \${profile['role']}'),
                  Text('Email: ${profile['email']}'),
                  Text('Rôle: ${profile['role']}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(token: token),
                        ),
                      );
                    },
                    child: Text('Voir le profil'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  final String token;
  UserProfilePage({required this.token});

  @override
  _UserProfilePageState createState() => _UserProfilePageState(token: token);
}

class _UserProfilePageState extends State<UserProfilePage> {
  final String token;
  String firebaseKey = '';
  String debugMode = '';
  String analytics = '';

  _UserProfilePageState({required this.token});

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    final response = await http.get(
      Uri.parse("http://10.0.2.2:3001/config")
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      setState(() {
        firebaseKey = result['firebaseKey'];
        debugMode = result['debugMode'] ? 'debugMode enable':'debugMode disable';
        analytics = result['analytics'] ? 'analytics enable':'anlytics disable';
      });
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Erreur réseau"),
          content: Text("Code: ${response.statusCode}, Body: ${response.body}"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profil utilisateur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('firebaseKey: $firebaseKey'),
            SizedBox(height: 10),
            Text('debugMode: $debugMode'),
            SizedBox(height: 10),
            Text('analytics: $analytics'),
          ],
        ),
      ),
    );
  }
}