import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/section.dart';
import '../../l10n/app_localizations.dart';
import 'path_cards.dart';

/// `/explore` — PRD section 7.2.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHScaffold(
      children: [
        ContentWidth(
          padVertical: const EdgeInsets.only(top: 36, bottom: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(
                index: 0,
                child: SectionTitle(
                  title: l.exploreTitle,
                  subtitle: l.exploreSubtitle,
                ),
              ),
              const SizedBox(height: 30),
              const FadeUp(index: 1, child: PathCards()),
            ],
          ),
        ),
      ],
    );
  }
}
