import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool isPasswordVisible = false;
  bool isLoading = false;
  bool isSendingReset = false;

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No user found for that email.',
        'wrong-password' => 'Wrong password provided.',
        'invalid-email' => 'Invalid email address.',
        'user-disabled' => 'This account has been disabled.',
        _ => e.message ?? 'Login failed',
      };
      _snack(msg);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      final c = TextEditingController();
      final entered = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: c,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Enter your registered email',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Send')),
          ],
        ),
      );
      if (entered == null || entered.isEmpty) return;
      email = entered;
    }
    await _sendResetEmail(email);
  }

  Future<void> _sendResetEmail(String email) async {
    setState(() => isSendingReset = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _snack('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'invalid-email' => 'Invalid email address.',
        'user-not-found' => 'No user found for that email.',
        'invalid-continue-uri' => 'Invalid continue URL (check Authorized domains).',
        'unauthorized-continue-uri' => 'Continue URL not whitelisted.',
        _ => e.message ?? 'Failed to send reset email',
      };
      _snack(msg);
    } finally {
      if (mounted) setState(() => isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = isLoading || isSendingReset;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_parking, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Smart Outdoor Parking Finder',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !busy,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: busy ? null : () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                enabled: !busy,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : _forgotPassword,
                  child: isSendingReset
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),

              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account?"),
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('Sign Up', style: TextStyle(color: Colors.blueAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
