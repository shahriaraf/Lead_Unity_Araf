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
    // 1. Get the current logged-in Supervisor's ID
    final myId = Provider.of<AuthProvider>(context, listen: false).user?['_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Select Team to Evaluate")),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getAllProposals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Error loading teams: ${snapshot.error}"));
          }

          var allTeams = snapshot.data ?? [];

          // 2. Filter: Only show teams assigned to THIS supervisor
          var myTeams = allTeams.where((t) {
              if (myId == null) return false;

              // Check 'supervisors' array (Preferences)
              final sups = t['supervisors'] as List? ?? [];
              bool isInPreferences = sups.any((s) {
                 // Handle if 's' is just an ID string or a populated User object
                 final sId = (s is Map) ? s['_id'] : s;
                 return sId == myId;
              });

              // Check 'assignedSupervisor' field (The definitive assignment)
              final assigned = t['assignedSupervisor'];
              final assignedId = (assigned is Map) ? assigned['_id'] : assigned;
              bool isAssigned = assignedId == myId;

              return isInPreferences || isAssigned;
          }).toList();

          if (myTeams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_ind_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("No teams assigned to you yet.", style: GoogleFonts.inter(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: myTeams.length,
            itemBuilder: (context, index) {
              final team = myTeams[index];
              
              // 3. Safety Checks to prevent "NoSuchMethodError: '[]'"
              final courseCode = team['course']?['courseCode'] ?? 'N/A';
              final title = team['title'] ?? 'Untitled Project';
              final studentName = team['student']?['name'] ?? 'Unknown Leader';
              final status = team['status']?.toString().toUpperCase() ?? 'PENDING';

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
                            child: Text(courseCode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                          ),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(
                               border: Border.all(color: Colors.grey.shade300),
                               borderRadius: BorderRadius.circular(4)
                             ),
                             child: Text(status, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1E293B))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("Leader: $studentName", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[700])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MarkingScreen(team: team)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
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