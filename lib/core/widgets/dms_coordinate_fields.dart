import 'package:flutter/material.dart';

import '../dms_coordinate.dart';

class DmsCoordinateFields extends StatelessWidget {
  const DmsCoordinateFields({
    super.key,
    required this.label,
    required this.coordinate,
    required this.onChanged,
  });

  final String label;
  final DmsCoordinate coordinate;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (controller, unit) in [
              (coordinate.degrees, 'Deg °'),
              (coordinate.minutes, 'Min ′'),
              (coordinate.seconds, 'Sec ″'),
            ]) ...[
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: unit),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 68,
              child: DropdownButtonFormField<String>(
                key: ValueKey(coordinate.hemisphere),
                initialValue: coordinate.hemisphere,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                items: [
                  for (final direction in [
                    coordinate.positive,
                    coordinate.negative,
                  ])
                    DropdownMenuItem(value: direction, child: Text(direction)),
                ],
                onChanged: (direction) {
                  if (direction == null) return;
                  coordinate.hemisphere = direction;
                  onChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
