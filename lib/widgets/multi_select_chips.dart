// lib/widgets/multi_select_chips.dart
import 'package:flutter/material.dart';

class MultiSelectChips extends StatefulWidget {
  final List<String> options;
  final List<String> initial;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectChips({
    super.key,
    required this.options,
    this.initial = const [],
    required this.onChanged,
  });

  @override
  State<MultiSelectChips> createState() => _MultiSelectChipsState();
}

class _MultiSelectChipsState extends State<MultiSelectChips> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = [...widget.initial];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.options.map((o) {
        final isSel = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: isSel,
          onSelected: (v) {
            setState(() {
              v ? selected.add(o) : selected.remove(o);
            });
            widget.onChanged(selected);
          },
        );
      }).toList(),
    );
  }
}
