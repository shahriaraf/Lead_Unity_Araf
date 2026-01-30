import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'student/student_dashboard.dart';
import 'supervisor/supervisor_dashboard.dart'; // Import Supervisor Dashboard
import 'supervisor/supervisor_first_login_screen.dart'; // Import First Login Screen
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _api = ApiService();
  bool _isRegOpen = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkRegStatus();
  }

  _checkRegStatus() async {
    bool status = await _api.isRegistrationOpen();
    if(mounted) setState(() => _isRegOpen = status);
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passController.text);
      
      if (!mounted) return;
      final user = Provider.of<AuthProvider>(context, listen: false).user;

      if (widget.role == 'student' && user?['role'] == 'student') {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const StudentDashboard()), (route) => false);
      } else if (widget.role == 'supervisor' && user?['role'] == 'supervisor') {
         // UPDATED: Navigate to the real Supervisor Dashboard
         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SupervisorDashboard()), (route) => false);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role mismatch or invalid credentials"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s Sign You In.',
                style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! You\'ve been missed.',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
              ),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded)),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Login'),
                ),
              ),
              
              // --- Supervisor Specific: Activate Account Link ---
              if (widget.role == 'supervisor')
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const SupervisorFirstLoginScreen())
                      ),
                      child: Text("First time login? Activate Account", style: GoogleFonts.inter(color: const Color(0xFF0F766E), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              
              // --- Student Specific: Registration Link ---
              if (widget.role == 'student')
                Center(
                  child: _isRegOpen
                      ? TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(color: Colors.grey[600], fontFamily: 'Inter'),
                              children: const [
                                TextSpan(text: 'Register Now', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                          child: const Text("Registration Closed", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}