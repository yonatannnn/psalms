import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/localization_service.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : null,
      appBar: AppBar(
        title: Text(LocalizationService.instance.currentLanguage == 'am' ? 'አድሚን' : 'Admin'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnap) {
            if (usersSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!usersSnap.hasData) {
              return const Center(child: Text('No users'));
            }

            final users = usersSnap.data!.docs
                .map((d) => {'id': d.id, ...(d.data() as Map<String, dynamic>)} )
                .toList();

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('reading_preferences').get(),
              builder: (context, prefsSnap) {
                final prefs = <String, Map<String, dynamic>>{};
                if (prefsSnap.hasData) {
                  for (final d in prefsSnap.data!.docs) {
                    prefs[d.id] = d.data() as Map<String, dynamic>;
                  }
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final pid = u['id'] as String;
                    final p = prefs[pid];
                    final username = u['username'] ?? '';
                    final password = u['password'] ?? '';
                    final dailyOpenCount = u['dailyOpenCount'] ?? 0;
                    final lastOpenDate = u['lastOpenDate'] ?? '';
                    final createdAt = u['createdAt'] ?? '';
                    final prefDaily = p != null ? p['dailyChapterCount'] : null;
                    final startDate = p != null ? p['startDate'] : null;
                    final perDay = p != null ? p['perDayChapterCounts'] : null;

                    return Card(
                      color: isDark ? Colors.grey.shade900 : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Colors.deepPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    username.toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text('opens: $dailyOpenCount'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _kv('Password', password.toString(), isDark),
                            _kv('Last Open Date', lastOpenDate.toString(), isDark),
                            const Divider(),
                            Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
                            _kv('Daily Chapters', prefDaily?.toString() ?? '- ', isDark),
                            _kv('Start Date', startDate?.toString() ?? '- ', isDark),
                            if (perDay != null) _kv('Per-day', perDay.toString(), isDark),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _kv(String k, String v, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(k, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
          Expanded(child: Text(v, style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }
}


