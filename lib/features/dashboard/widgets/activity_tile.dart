import 'package:flutter/material.dart';
import '../models/dashboard_summary.dart';

class ActivityTile extends StatelessWidget {
  final RecentActivity activity;

  const ActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    // Format timestamp nicely
    String displayTime = activity.timestamp;
    try {
      final parsed = DateTime.parse(activity.timestamp).toLocal();
      displayTime = "${parsed.day}/${parsed.month} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (_) {}

    // Icon depending on the module
    IconData icon = Icons.info_rounded;
    Color color = Colors.indigoAccent;

    if (activity.module.toLowerCase().contains("property")) {
      icon = Icons.home_work_rounded;
      color = Colors.cyanAccent;
    } else if (activity.module.toLowerCase().contains("requirement")) {
      icon = Icons.assignment_turned_in_rounded;
      color = Colors.tealAccent;
    } else if (activity.module.toLowerCase().contains("user")) {
      icon = Icons.person_rounded;
      color = Colors.orangeAccent;
    } else if (activity.action.toLowerCase().contains("import")) {
      icon = Icons.upload_file_rounded;
      color = Colors.purpleAccent;
    } else if (activity.action.toLowerCase().contains("export")) {
      icon = Icons.download_rounded;
      color = Colors.blueAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 1),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.user,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      displayTime,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8), // Slate 400
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCBD5E1), // Slate 300
                  ),
                ),
                const Divider(height: 20, color: Colors.white10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
