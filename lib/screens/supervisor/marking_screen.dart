import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class MarkingScreen extends StatefulWidget {
  final Map<String, dynamic> team;
  const MarkingScreen({Key? key, required this.team}) : super(key: key);

  @override
  _MarkingScreenState createState() => _MarkingScreenState();
}

class _MarkingScreenState extends State<MarkingScreen> {
  Map<String, dynamic>? _settings;
  bool _isLoading = true;
  
  // Marks State: { studentId: { c1: 0, c2: 0, absent: false, data: {} } }
  final Map<String, Map<String, dynamic>> _studentMarks = {};

  @override
  void initState() {
    super.initState();
    _loadSettingsAndMarks();
  }

  _loadSettingsAndMarks() async {
    // 1. Fetch Criteria Settings (from Admin)
    final s = await ApiService().getEvaluationSettings();
    
    // 2. Map Existing Saved Marks (if any)
    final List<dynamic> existingMarksList = widget.team['marks'] ?? [];
    Map<String, dynamic> existingMarksMap = {};
    for (var m in existingMarksList) {
      existingMarksMap[m['studentId']] = m;
    }

    // 3. Get ONLY Team Members (Removed User/Leader injection logic)
    final allStudents = [...widget.team['teamMembers']];

    // 4. Initialize Local State
    for (var student in allStudents) {
      // Use studentId field or _id as fallback
      String uid = student['studentId'] ?? student['_id']; 
      
      if (existingMarksMap.containsKey(uid)) {
        // Load Saved Data (Editable)
        var saved = existingMarksMap[uid];
        _studentMarks[uid] = {
          'c1': (saved['criteria1'] ?? 0).toDouble(),
          'c2': (saved['criteria2'] ?? 0).toDouble(),
          'absent': saved['isAbsent'] ?? false,
          'data': student
        };
      } else {
        // New Entry
        _studentMarks[uid] = {
          'c1': 0.0,
          'c2': 0.0,
          'absent': false,
          'data': student
        };
      }
    }

    if (mounted) {
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    }
  }

  void _submitMarks() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> payload = [];
    
    _studentMarks.forEach((key, value) {
      payload.add({
        'studentId': key,
        'criteria1': value['c1'],
        'criteria2': value['c2'],
        'isAbsent': value['absent']
      });
    });

    try {
      await ApiService().saveTeamMarks(widget.team['_id'], payload);
      if(mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evaluations Saved Successfully"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
         setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final c1Name = _settings?['criteria1']['name'];
    final c1Max = _settings?['criteria1']['max'];
    final c2Name = _settings?['criteria2']['name'];
    final c2Max = _settings?['criteria2']['max'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Evaluation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Text(widget.team['title'], style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCriteriaRow("Criteria 1", c1Name, c1Max),
                  const SizedBox(height: 8),
                  _buildCriteriaRow("Criteria 2", c2Name, c2Max),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Marking Cards
            ..._studentMarks.keys.map((uid) {
              return StudentMarkingCard(
                studentData: _studentMarks[uid]!['data'],
                marksData: _studentMarks[uid]!,
                maxC1: c1Max,
                maxC2: c2Max,
                onChanged: (updatedMarks) {
                  _studentMarks[uid] = updatedMarks;
                  // No setState needed, values updated by reference
                },
              );
            }).toList(),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitMarks,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save_rounded),
                    SizedBox(width: 10),
                    Text("Submit Evaluations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaRow(String label, String name, int max) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
        Expanded(child: Text("$name ($max Marks)", style: GoogleFonts.inter())),
      ],
    );
  }
}

// --- ISOLATED WIDGET FOR MARKING CARD ---
class StudentMarkingCard extends StatefulWidget {
  final dynamic studentData;
  final Map<String, dynamic> marksData;
  final int maxC1;
  final int maxC2;
  final Function(Map<String, dynamic>) onChanged;

  const StudentMarkingCard({
    Key? key,
    required this.studentData,
    required this.marksData,
    required this.maxC1,
    required this.maxC2,
    required this.onChanged,
  }) : super(key: key);

  @override
  _StudentMarkingCardState createState() => _StudentMarkingCardState();
}

class _StudentMarkingCardState extends State<StudentMarkingCard> {
  late bool _isAbsent;
  final _c1Ctrl = TextEditingController();
  final _c2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isAbsent = widget.marksData['absent'];
    // Handle 0.0 display as "0" or empty if preferred, currently raw string
    _c1Ctrl.text = widget.marksData['c1'] == 0.0 ? '' : widget.marksData['c1'].toString();
    _c2Ctrl.text = widget.marksData['c2'] == 0.0 ? '' : widget.marksData['c2'].toString();
  }

  void _update() {
    double c1 = double.tryParse(_c1Ctrl.text) ?? 0;
    double c2 = double.tryParse(_c2Ctrl.text) ?? 0;

    // Enforce Max Limit logic
    if (c1 > widget.maxC1) { 
      c1 = widget.maxC1.toDouble(); 
      _c1Ctrl.text = c1.toString(); 
      _c1Ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _c1Ctrl.text.length));
    }
    if (c2 > widget.maxC2) { 
      c2 = widget.maxC2.toDouble(); 
      _c2Ctrl.text = c2.toString(); 
      _c2Ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _c2Ctrl.text.length));
    }

    widget.onChanged({
      'data': widget.marksData['data'],
      'c1': c1,
      'c2': c2,
      'absent': _isAbsent
    });
    
    // Trigger rebuild to update Total box
    setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    double total = (double.tryParse(_c1Ctrl.text) ?? 0) + (double.tryParse(_c2Ctrl.text) ?? 0);
    String name = widget.studentData['name'] ?? 'Unknown';
    String id = widget.studentData['studentId'] ?? widget.studentData['_id'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)], // Teal 50-100
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF004D40))),
                    Text(id, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF00695C))),
                  ],
                ),
                Column(
                  children: [
                    Switch(
                      value: _isAbsent,
                      activeColor: Colors.redAccent,
                      onChanged: (val) {
                        setState(() => _isAbsent = val);
                        _update();
                      },
                    ),
                    Text("Absent", style: GoogleFonts.inter(fontSize: 10, color: _isAbsent ? Colors.red : Colors.grey)),
                  ],
                )
              ],
            ),
          ),

          // Body
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isAbsent ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text("Marked as Absent", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(child: _buildInputBox("Criteria 1", _c1Ctrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInputBox("Criteria 2", _c2Ctrl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300)
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Total", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Text(total.toStringAsFixed(0), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(String label, TextEditingController ctrl) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: (_) => _update(),
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        ),
      ),
    );
  }
}