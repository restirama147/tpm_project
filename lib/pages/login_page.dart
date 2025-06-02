import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:project_tpm/pages/home_page.dart';
import 'package:project_tpm/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/encryption.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _usernameError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString("username");

    if (savedUsername != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => HomePage(username: savedUsername),
      ));
    }
  }

  void _login(BuildContext context) async {
    setState(() {
      _usernameError = null;
      _passwordError = null;
      _generalError = null;
    });

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    bool hasError = false;

    if (username.isEmpty) {
      _usernameError = 'Please enter your username.';
      hasError = true;
    }
    if (password.isEmpty) {
      _passwordError = 'Please enter your password.';
      hasError = true;
    }

    if (hasError) {
      setState(() {}); 
      return;
    }

    var box = Hive.box('users');
    bool userExists = box.containsKey(username);

    if (!userExists) {
      setState(() {
        _generalError = 'Username not found. Please register first.';
      });
      return;
    }

    String storedHashedPassword = box.get(username);

    if (storedHashedPassword != hashPassword(password)) {
      setState(() {
        _generalError = 'Incorrect password. Please try again.';
      });
      return;
    }

    // Successful login
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('username', username);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(username: username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color blueBg = const Color.fromARGB(255, 166, 192, 235);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [blueBg.withOpacity(0.9), blueBg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: blueBg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to access',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _usernameError,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          errorText: _passwordError,
                        ),
                      ),

                      if (_generalError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _generalError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _login(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blueBg,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: blueBg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
