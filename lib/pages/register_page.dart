import 'package:flutter/material.dart';
import 'package:project_tpm/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../utils/encryption.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? usernameError;
  String? passwordError;
  String? generalError;
  bool _obscurePassword = true;

  bool isPasswordValid(String password) {
    final hasLetters = password.contains(RegExp(r'[A-Za-z]'));
    final hasDigits = password.contains(RegExp(r'\d'));
    return hasLetters && hasDigits;
  }

  void _register() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text;

    setState(() {
      usernameError = null;
      passwordError = null;
      generalError = null;
    });

    bool valid = true;

    if (username.isEmpty) {
      usernameError = "Username cannot be empty.";
      valid = false;
    } else if (username.length < 5) {
      usernameError = "Username must be at least 5 characters.";
      valid = false;
    }

    if (password.isEmpty) {
      passwordError = "Password cannot be empty.";
      valid = false;
    } else if (password.length < 5) {
      passwordError = "Password must be at least 5 characters.";
      valid = false;
    } else if (!isPasswordValid(password)) {
      passwordError = "Password must contain both letters and numbers.";
      valid = false;
    }

    setState(() {}); // refresh UI to show errors

    if (!valid) return;

    var box = Hive.box('users');
    if (box.containsKey(username)) {
      setState(() {
        generalError = "Username is already registered.";
      });
      return;
    }

    // Simpan password yang sudah di-hash ke Hive dan SharedPreferences
    final hashedPassword = hashPassword(password);
    await box.put(username, hashedPassword);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_$username', hashedPassword);

    // Tampilkan pesan berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration successful!")),
    );

    // Beri delay agar SnackBar terlihat dulu, baru pindah halaman
    await Future.delayed(const Duration(milliseconds: 800));

    // Navigasi ke halaman Login (replace halaman sekarang)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color pinkColor = const Color.fromARGB(221, 246, 74, 148);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pinkColor.withOpacity(0.9), pinkColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1, size: 60, color: pinkColor),
                    const SizedBox(height: 12),
                    Text(
                      'Create New Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: pinkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register your account to access Makeup Store',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        errorText: usernameError,
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: passwordError,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
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
                      ),
                    ),

                    if (generalError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        generalError!,
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
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pinkColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: pinkColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
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
    );
  }
}
