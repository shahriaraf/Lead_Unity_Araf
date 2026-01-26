import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({Key? key}) : super(key: key);

  @override
  _SubmitProposalScreenState createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  
  List<dynamic> _courses = [];
  List<dynamic> _supervisors = [];
  String? _selectedCourse;
  
  String? _sup1, _sup2, _sup3;
  String _title = '';
  String _driveLink = ''; 

  List<Map<String, String>> _members = [];

  @override
  void initState() {
    super.initState();
    _members = List.generate(3, (index) => {
      'name': '', 'studentId': '', 'cgpa': '', 'email': '', 'mobile': ''
    });
    _loadData();
  }

  _loadData() async {
    try {
      final c = await _api.getCourses();
      final u = await _api.getUsers();
      if (mounted) {
        setState(() {
          _courses = c;
          _supervisors = u.where((user) => user['role'] == 'supervisor').toList();
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  void _addMember() {
    if (_members.length < 4) {
      setState(() {
        _members.add({'name': '', 'studentId': '', 'cgpa': '', 'email': '', 'mobile': ''});
      });
    }
  }

  void _removeMember(int index) {
    if (index == 3) setState(() => _members.removeAt(index));
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Basic Duplication Check
      List<String> allIds = _members.map((m) => m['studentId']!).toList();
      if (allIds.toSet().length != allIds.length) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Duplicate Student IDs found'), backgroundColor: Colors.red));
        return;
      }

      List<String> sups = [];
      if (_sup1 != null) sups.add(_sup1!);
      if (_sup2 != null) sups.add(_sup2!);
      if (_sup3 != null) sups.add(_sup3!);

      final data = {
        'title': _title,
        'description': _driveLink,
        'courseId': _selectedCourse,
        'supervisorIds': sups,
        'teamMembers': _members
      };

      try {
        await _api.submitProposal(data);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proposal Submitted Successfully!'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('New Proposal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Project Basics", Icons.article_outlined),
              const SizedBox(height: 15),
              _buildCardContainer(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCourse,
                      hint: const Text('Select Course Code'),
                      items: _courses.map<DropdownMenuItem<String>>((c) {
                        return DropdownMenuItem(value: c['_id'], child: Text(c['courseCode']));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCourse = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Project Title'),
                      onSaved: (v) => _title = v!,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Google Drive Link', suffixIcon: Icon(Icons.link)),
                      onSaved: (v) => _driveLink = v!,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("Supervisors", Icons.school_outlined),
              const SizedBox(height: 5),
              const Text("Select 3 preferences", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildSupDropdown(1)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSupDropdown(2)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildSupDropdown(3)),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("The Team", Icons.groups_outlined),
              const SizedBox(height: 15),

              ..._members.asMap().entries.map((entry) {
                return _buildMemberCard(entry.key, entry.value);
              }).toList(),

              if (_members.length < 4)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      onPressed: _addMember,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Add 4th Member (Optional)"),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Submit Proposal'),
                    SizedBox(width: 8),
                    Icon(Icons.send_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0F766E), size: 20),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildSupDropdown(int index) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
        hint: Text('Sup $index', style: const TextStyle(fontSize: 12)),
        items: _supervisors.map<DropdownMenuItem<String>>((s) {
          return DropdownMenuItem(value: s['_id'], child: Text(s['name'].toString().split(' ')[0], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)));
        }).toList(),
        onChanged: (v) {
          setState(() {
            if (index == 1) _sup1 = v;
            if (index == 2) _sup2 = v;
            if (index == 3) _sup3 = v;
          });
        },
      ),
    );
  }

  Widget _buildMemberCard(int index, Map<String, String> member) {
    bool isLeader = index == 0;
    bool isOptional = index == 3;

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isLeader ? const Color(0xFF0F766E).withOpacity(0.3) : Colors.transparent),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isLeader ? const Color(0xFF0F766E).withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(isLeader ? Icons.star_rounded : Icons.person_outline, 
                         color: isLeader ? const Color(0xFFF59E0B) : Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isLeader ? "Team Leader" : "Member ${index + 1}", 
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: isLeader ? const Color(0xFF0F766E) : Colors.grey[700])
                    ),
                    const Spacer(),
                    if (isOptional)
                      InkWell(
                        onTap: () => _removeMember(index),
                        child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                      )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: member['name'],
                      decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                      onChanged: (v) => member['name'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: member['studentId'],
                            decoration: const InputDecoration(labelText: 'Student ID', prefixIcon: Icon(Icons.numbers, size: 18)),
                            onChanged: (v) => member['studentId'] = v,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: member['cgpa'],
                            decoration: const InputDecoration(labelText: 'CGPA'),
                            onChanged: (v) => member['cgpa'] = v,
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: member['email'],
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email, size: 18)),
                      onChanged: (v) => member['email'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: member['mobile'],
                      decoration: const InputDecoration(labelText: 'Mobile', prefixIcon: Icon(Icons.phone_outlined, size: 18)),
                      onChanged: (v) => member['mobile'] = v,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}