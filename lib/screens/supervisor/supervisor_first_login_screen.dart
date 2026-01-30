import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class SupervisorFirstLoginScreen extends StatefulWidget {
  const SupervisorFirstLoginScreen({Key? key}) : super(key: key);

  @override
  _SupervisorFirstLoginScreenState createState() => _SupervisorFirstLoginScreenState();
}

class _SupervisorFirstLoginScreenState extends State<SupervisorFirstLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _tempPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ApiService().changePasswordFirstLogin(
          _emailCtrl.text, 
          _tempPassCtrl.text, 
          _newPassCtrl.text
        );
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Updated! Please Login."), backgroundColor: Colors.green));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Activate Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Security Update", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 10),
              Text("Please enter the temporary credentials provided by the admin and set a new secure password.", style: GoogleFonts.inter(color: Colors.grey[600])),
              const SizedBox(height: 30),
              
              TextFormField(
                controller: _emailCtrl, 
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)), 
                validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _tempPassCtrl, 
                decoration: const InputDecoration(labelText: "Temporary Password", prefixIcon: Icon(Icons.lock_open)), 
                obscureText: true, 
                validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _newPassCtrl, 
                decoration: const InputDecoration(labelText: "New Password", prefixIcon: Icon(Icons.lock_outline)), 
                obscureText: true, 
                validator: (v) => v!.length < 6 ? "Min 6 chars" : null
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit, 
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Update & Activate"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}