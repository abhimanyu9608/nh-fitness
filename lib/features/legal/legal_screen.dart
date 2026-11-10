import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/repositories/settings_repository.dart';
import '../../l10n/app_localizations.dart';

/// PRD section 7.11.
enum LegalPage { privacy, terms, refund }

/// `/privacy`, `/terms`, `/refund-policy`.
///
/// The body text is deliberately a placeholder — the gym's own wording has to
/// go in before the app stores will accept a submission. The privacy page does
/// carry real content for the two things PRD section 7.11 requires: what data
/// is stored, and how to ask for deletion.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.page});

  final LegalPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider).value;

    final title = switch (page) {
      LegalPage.privacy => l.legalPrivacyTitle,
      LegalPage.terms => l.legalTermsTitle,
      LegalPage.refund => l.legalRefundTitle,
    };

    return NHScaffold(
      children: [
        ContentWidth(
          maxWidth: 820,
          padVertical: const EdgeInsets.only(top: 36, bottom: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(index: 0, child: SectionTitle(title: title)),
              const SizedBox(height: 20),
              FadeUp(
                index: 1,
                child: InlineNotice(
                  message: l.legalPlaceholder,
                  icon: Icons.edit_note_outlined,
                  color: NHColors.yellow,
                ),
              ),
              const SizedBox(height: 24),
              if (page == LegalPage.privacy)
                FadeUp(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Block(
                        heading: l.legalDataWeStoreTitle,
                        body: l.legalDataWeStoreBody,
                      ),
                      const SizedBox(height: 18),
                      _Block(
                        heading: l.legalDeletionTitle,
                        body: l.legalDeletionBody(
                          settings?.hasEmail ?? false
                              ? settings!.email
                              : l.legalPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return NHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading.toUpperCase(), style: NHText.display(size: 24)),
          const SizedBox(height: 10),
          Text(body, style: NHText.body(size: 15.5, color: NHColors.muted)),
        ],
      ),
    );
  }
}
