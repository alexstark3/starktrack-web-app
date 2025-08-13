import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'today_line.dart';
import 'time_entry_card.dart';
import 'chips_card.dart';
import 'package:starktrack/screens/modules/time_tracker/logs_list.dart';
import '../../../theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  // Stable key so TimeEntryCard's State is always reused
  static final GlobalKey _entryCardKey = GlobalKey();

  // Cache "today" once so the same DateTime instance is reused
  late final DateTime _today;

  // Cache the projects future so it isn't recreated on every rebuild
  Future<List<Map<String, String>>>? _projectsFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);

    // Initialize the projects future immediately
    _projectsFuture = _fetchProjects();
  }

  Future<List<Map<String, String>>> _fetchProjects() async {
    try {
      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Verify the authenticated user matches the widget user
      if (currentUser.uid != widget.userId) {
        throw Exception('User ID mismatch');
      }

      // Check if user exists in company users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found in company');
      }
      // Fetch all projects for this company
      final snapshot = await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('projects')
          .get();

      return snapshot.docs
          .map((d) => {
                'id': d.id,
                'name': (d.data()['name'] as String?) ?? d.id,
              })
          .where((proj) => (proj['name'] ?? '').toString().trim().isNotEmpty)
          .toList();
    } catch (e) {
      rethrow;
    }
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
      backgroundColor: Theme.of(context).extension<AppColors>()!.backgroundDark,
      resizeToAvoidBottomInset: false,
      body: _projectsFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, String>>>(
              future: _projectsFuture,
              builder: (context, projectSnap) {
                if (projectSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (projectSnap.hasError) {
                  return Center(
                      child:
                          Text('Error loading projects: ${projectSnap.error}'));
                }
                // Allow Time Tracker to function even if there are no projects
                final projects = projectSnap.data ?? <Map<String, String>>[];

                // === NEW: Listen to user document for showBreaks toggle ===
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('companies')
                      .doc(widget.companyId)
                      .collection('users')
                      .doc(widget.userId)
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>? ?? {};

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
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
                              projects: projects
                                  .map((p) => p['name'] as String)
                                  .toList(),
                            ),
                            const SizedBox(height: 10),

                            /// Chips + Logs
                            StreamBuilder<QuerySnapshot>(
                              stream: logsRef.snapshots(),
                              builder: (context, snap) {
                                Duration worked = Duration.zero,
                                    breaks = Duration.zero;
                                List<Map<String, dynamic>> logs = [];

                                if (snap.hasData &&
                                    snap.data!.docs.isNotEmpty) {
                                  for (var doc in snap.data!.docs) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    logs.add({...data, 'logId': doc.id});

                                    final begin =
                                        (data['begin'] as Timestamp?)?.toDate();
                                    final end =
                                        (data['end'] as Timestamp?)?.toDate();
                                    if (begin != null && end != null) {
                                      worked += end.difference(begin);
                                    }
                                  }
                                  logs.sort((a, b) {
                                    final aBegin =
                                        (a['begin'] as Timestamp?)?.toDate();
                                    final bBegin =
                                        (b['begin'] as Timestamp?)?.toDate();
                                    return (aBegin ?? DateTime(2000))
                                        .compareTo(bBegin ?? DateTime(2000));
                                  });
                                  for (int i = 1; i < logs.length; i++) {
                                    final prevEnd =
                                        (logs[i - 1]['end'] as Timestamp?)
                                            ?.toDate();
                                    final thisBeg =
                                        (logs[i]['begin'] as Timestamp?)
                                            ?.toDate();
                                    if (prevEnd != null &&
                                        thisBeg != null &&
                                        prevEnd.isBefore(thisBeg)) {
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
                                      showBreaks: userData['showBreaks'] !=
                                          false, // default: true
                                    ),
                                    const SizedBox(height: 10),
                                    LogsList(
                                      companyId: widget.companyId,
                                      userId: widget.userId,
                                      selectedDay: _today,
                                      projects: projects,
                                      showBreakCards: userData['showBreaks'] !=
                                          false, // <-- LINKED TO USER!
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
                );
              },
            ),
    );
  }
}
