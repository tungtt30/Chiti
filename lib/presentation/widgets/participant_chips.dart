import 'package:flutter/material.dart';

import '../../data/models/models.dart';

/// A colored avatar circle for a participant.
class ParticipantAvatar extends StatelessWidget {
  final Participant participant;
  final double radius;

  const ParticipantAvatar({
    super.key,
    required this.participant,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(participant.color),
      child: Text(
        participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Selectable chips for choosing which participants are part of an expense.
class ParticipantChipSelector extends StatelessWidget {
  final List<Participant> participants;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  const ParticipantChipSelector({
    super.key,
    required this.participants,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: participants.map((p) {
        final selected = selectedIds.contains(p.id);
        return FilterChip(
          selected: selected,
          avatar: ParticipantAvatar(participant: p, radius: 14),
          label: Text(p.name),
          onSelected: (value) {
            final next = Set<String>.from(selectedIds);
            if (value) {
              next.add(p.id);
            } else {
              next.remove(p.id);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
