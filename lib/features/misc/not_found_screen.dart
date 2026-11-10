import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/section.dart';
import '../../l10n/app_localizations.dart';

/// PRD section 6: "any other → 404 page with 'Back to home'".
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHScaffold(
      children: [
        ContentWidth(
          maxWidth: 700,
          padVertical: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('404', style: NHText.display(size: 110, color: NHColors.red)),
              const SizedBox(height: 10),
              SectionTitle(title: l.notFoundTitle, subtitle: l.notFoundBody),
              const SizedBox(height: 26),
              PrimaryButton(
                label: l.actionBackToHome,
                expand: false,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
