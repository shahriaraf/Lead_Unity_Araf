import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'marking_screen.dart';

class MarkingSelectionScreen extends StatelessWidget {
  const MarkingSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myId = Provider.of<AuthProvider>(context, listen: false).user?['_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Evaluation")),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // Only show teams assigned to this supervisor
          var teams = (snapshot.data ?? []).where((t) {
              final sups = t['supervisors'] as List;
              return sups.any((s) => s['_id'] == myId || s == myId);
          }).toList();

          if (teams.isEmpty) return const Center(child: Text("No assigned teams to mark."));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF0F766E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(team['course']['courseCode'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          ),
                          Icon(Icons.more_horiz, color: Colors.grey[400])
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(team['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MarkingScreen(team: team)));
                          },
                          child: const Text("Start Evaluation"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}