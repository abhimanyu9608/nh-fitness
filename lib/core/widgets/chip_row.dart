import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A selectable pill. Used for the class category filters (PRD section 7.7),
/// the payment status tabs and the member filters (PRD section 7.10).
class NHChip extends StatelessWidget {
  const NHChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? NHColors.selectedBg : NHColors.surface,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              constraints: const BoxConstraints(minHeight: NHSizes.minTouchTarget),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? NHColors.red : NHColors.line,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: NHText.body(
                      size: 14.5,
                      weight: FontWeight.w600,
                      color: selected ? NHColors.text : NHColors.muted,
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 7), badge!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapping row of [NHChip]s where exactly one is selected.
class ChipRow extends StatelessWidget {
  const ChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          NHChip(
            label: labels[i],
            selected: i == selectedIndex,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}
