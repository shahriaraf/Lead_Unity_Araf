import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'marking_screen.dart';
import 'supervisor_team_details_screen.dart'; // <--- 1. Import this

class TeamListScreen extends StatelessWidget {
  final bool onlyMyTeams;
  const TeamListScreen({Key? key, required this.onlyMyTeams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myId = Provider.of<AuthProvider>(context, listen: false).user?['_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(onlyMyTeams ? "My Assigned Teams" : "All Registered Teams")),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          var teams = snapshot.data ?? [];

          // Keep filtering ONLY if the user explicitly clicked "My Teams"
          if (onlyMyTeams && myId != null) {
            teams = teams.where((t) {
              final sups = t['supervisors'] as List;
              return sups.any((s) => s['_id'] == myId || s == myId);
            }).toList();
          }

          if (teams.isEmpty) return const Center(child: Text("No teams found."));

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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: Text(team['title'][0].toUpperCase(), style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(team['title'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text("${team['course']['courseCode']} • ${team['status'].toString().toUpperCase()}", style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      const Divider(),
                      // --- Action Bar ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Details Button
                          TextButton(
                            onPressed: () {
                               // <--- 2. Update this Navigation logic
                               Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorTeamDetailsScreen(team: team)));
                            }, 
                            child: const Text("Details", style: TextStyle(color: Colors.grey))
                          ),
                          const SizedBox(width: 8),
                          // Evaluate Button
                          ElevatedButton.icon(
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => MarkingScreen(team: team)));
                            },
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text("Evaluate"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B), 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                          )
                        ],
                      )
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