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

const categoryIcons = {
  'study': Icons.menu_book_rounded,
  'work': Icons.work_rounded,
  'personal': Icons.person_rounded,
  'university': Icons.school_rounded,
  'exercise': Icons.fitness_center_rounded,
  'meeting': Icons.groups_rounded,
  'important': Icons.star_rounded,
  'other': Icons.label_rounded,
};

IconData getCategoryIcon(String category) =>
    categoryIcons[category] ?? Icons.event_rounded;

class EventCard extends StatelessWidget {
  const EventCard(
      {super.key, required this.event, required this.segment, this.onTap});
  final Event event;
  final DaySegment segment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColors[event.category] ?? categoryColors['other']!;
    final icon = getCategoryIcon(event.category);
    final lang = langOf(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Card(
      color: color.withOpacity(.14),
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: BorderDirectional(start: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  if (segment.continuesFromPrevDay)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back,
                          size: 11, color: Colors.grey),
                    ),
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                  if (segment.continuesToNextDay)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward,
                          size: 11, color: Colors.grey),
                    ),
                  if (event.importance == 'critical')
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.alarm, size: 14, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 2),
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
