import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'today_line.dart';
import 'time_entry_card.dart';
import 'chips_card.dart';
import 'package:starktrack/screens/modules/time_tracker/logs_list.dart';

class TimeTrackerScreen extends StatefulWidget {
  final String companyId;
  final String userId;

  const TimeTrackerScreen({
    Key? key,
    required this.companyId,
    required this.userId,
  }) : super(key: key);

  @override
  State<TimeTrackerScreen> createState() => _TimeTrackerScreenState();
}

class _TimeTrackerScreenState extends State<TimeTrackerScreen> {
  // Stable key so TimeEntryCard’s State is always reused
  static final GlobalKey _entryCardKey = GlobalKey();

  // Cache “today” once so the same DateTime instance is reused
  late final DateTime _today;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = DateFormat('yyyy-MM-dd').format(_today);

    final logsRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .collection('users')
        .doc(widget.userId)
        .collection('all_logs')
        .where('sessionDate', isEqualTo: sessionId)
        .orderBy('begin');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .collection('projects')
            .snapshots(),
        builder: (context, projectSnap) {
          if (projectSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (projectSnap.hasError) {
            return Center(child: Text('Error loading projects: ${projectSnap.error}'));
          }
          if (!projectSnap.hasData || projectSnap.data!.docs.isEmpty) {
            return const Center(child: Text('No projects found in Firestore.'));
          }

          final projects = projectSnap.data!.docs
              .map((d) => (d.data() as Map<String, dynamic>)['name'] as String)
              .where((name) => name.trim().isNotEmpty)
              .toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TodayLine(),
                  const SizedBox(height: 10),

                  /// Time-entry card – key guarantees the same State object
                  TimeEntryCard(
                    key: _entryCardKey,
                    companyId: widget.companyId,
                    userId: widget.userId,
                    selectedDay: _today,
                    projects: projects,
                  ),
                  const SizedBox(height: 10),

                  /// Chips + Logs
                  StreamBuilder<QuerySnapshot>(
                    stream: logsRef.snapshots(),
                    builder: (context, snap) {
                      Duration worked = Duration.zero, breaks = Duration.zero;
                      List<Map<String, dynamic>> logs = [];

                      if (snap.hasData && snap.data!.docs.isNotEmpty) {
                        for (var doc in snap.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          logs.add({...data, 'logId': doc.id});

                          final begin = (data['begin'] as Timestamp?)?.toDate();
                          final end   = (data['end']   as Timestamp?)?.toDate();
                          if (begin != null && end != null) worked += end.difference(begin);
                        }
                        logs.sort((a, b) {
                          final aBegin = (a['begin'] as Timestamp?)?.toDate();
                          final bBegin = (b['begin'] as Timestamp?)?.toDate();
                          return (aBegin ?? DateTime(2000)).compareTo(bBegin ?? DateTime(2000));
                        });
                        for (int i = 1; i < logs.length; i++) {
                          final prevEnd = (logs[i - 1]['end'] as Timestamp?)?.toDate();
                          final thisBeg = (logs[i]['begin'] as Timestamp?)?.toDate();
                          if (prevEnd != null && thisBeg != null && prevEnd.isBefore(thisBeg)) {
                            breaks += thisBeg.difference(prevEnd);
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChipsCard(
                            worked: worked,
                            breaks: breaks,
                          ),
                          const SizedBox(height: 10),
                          LogsList(
                            companyId: widget.companyId,
                            userId: widget.userId,
                            selectedDay: _today,
                            projects: projects,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
