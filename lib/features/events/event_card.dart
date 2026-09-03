import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/db.dart';
import '../../domain/event_engine.dart';

const categoryColors = {
  'study': Color(0xFF4C6EF5),
  'work': Color(0xFF12B886),
  'personal': Color(0xFFE8590C),
  'university': Color(0xFF7048E8),
  'exercise': Color(0xFF2B8A3E),
  'meeting': Color(0xFFC92A2A),
  'important': Color(0xFFF08C00),
  'other': Color(0xFF868E96),
};

class EventCard extends StatelessWidget {
  const EventCard(
      {super.key, required this.event, required this.segment, this.onTap});
  final Event event;
  final DaySegment segment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[event.category] ?? categoryColors['other']!;
    final lang = langOf(context);
    return Card(
      color: color.withOpacity(.14),
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (segment.continuesFromPrevDay)
                    const Icon(Icons.arrow_back, size: 12, color: Colors.grey),
                  Expanded(
                    child: Text(event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: color)),
                  ),
                  if (segment.continuesToNextDay)
                    const Icon(Icons.arrow_forward,
                        size: 12, color: Colors.grey),
                  if (event.importance == 'critical')
                    const Icon(Icons.priority_high,
                        size: 14, color: Colors.red),
                ],
              ),
              Text(
                '${fmtTime(segment.start, lang)} – ${fmtTime(segment.end, lang)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
