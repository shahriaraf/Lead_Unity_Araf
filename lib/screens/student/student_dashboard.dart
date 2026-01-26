import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'submit_proposal_screen.dart';
import 'team_info_screen.dart';
import 'request_join_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
              child: Text(user?['name']?[0] ?? 'S', style: const TextStyle(color: Color(0xFF0F766E))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?['name'] ?? 'Student'}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(user?['studentId'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1, // Slightly wider cards
              children: [
                 _buildDashCard('Team Info', 'View your team details', Icons.groups_rounded, const Color(0xFF3B82F6), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamInfoScreen()))),
                 
                 _buildDashCard('Proposal', 'Submit new project', Icons.assignment_add, const Color(0xFFF59E0B), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitProposalScreen()))),
                 
                 _buildDashCard('Templates', 'Download resources', Icons.folder_open_rounded, const Color(0xFF8B5CF6), 
                    () {}), 
                 
                 _buildDashCard('Find Members', 'Request to join', Icons.person_search_rounded, const Color(0xFF10B981), 
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestJoinScreen()))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}