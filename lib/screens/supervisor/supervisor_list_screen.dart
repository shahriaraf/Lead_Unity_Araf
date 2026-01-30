import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class SupervisorListScreen extends StatelessWidget {
  const SupervisorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("All Supervisors")),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final sups = snapshot.data?.where((u) => u['role'] == 'supervisor').toList() ?? [];
          
          if (sups.isEmpty) return const Center(child: Text("No other supervisors found."));

          return ListView.builder(
            itemCount: sups.length,
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final s = sups[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF3E5F5),
                    child: Text(s['name'][0], style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(s['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(s['email'], style: GoogleFonts.inter(fontSize: 12)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}