import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/class_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/verify_email_banner.dart';
import '../classes/class_tile.dart';
import 'account_shell.dart';
import 'membership_card.dart';
import 'payment_row.dart';

/// `/account` — the member dashboard (PRD section 7.6).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider).value;

    return AccountShell(
      title: l.accountTitle,
      showAnnouncement: true,
      aboveTitle: user == null
          ? null
          : Text(
              l.accountGreeting(firstName(user.name)),
              style: NHText.body(size: 17, color: NHColors.muted),
            ),
      children: [
        // PRD AUTH-1: the banner stays until the email is verified, and never
        // blocks anything.
        const FadeUp(index: 1, child: VerifyEmailBanner()),
        const _Gap(),
        const FadeUp(index: 2, child: ExpiryBanner()),
        const _Gap(),
        const FadeUp(index: 3, child: MembershipStatusCard()),
        const SizedBox(height: 18),
        const FadeUp(index: 4, child: FreePtCard()),
        const SizedBox(height: 18),
        const FadeUp(index: 5, child: _ClassesPreview()),
        const SizedBox(height: 18),
        const FadeUp(index: 6, child: _PaymentsPreview()),
      ],
    );
  }
}

/// Collapses to nothing when the widget above it rendered nothing, so the
/// dashboard has no empty gaps.
class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 14);
}

/// PRD section 7.6 item 5: "Online classes preview (3 latest) →
/// `/account/classes`".
class _ClassesPreview extends ConsumerWidget {
  const _ClassesPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final user = ref.watch(currentUserProvider).value;
    final classes = ref.watch(publishedClassesProvider);

    // PRD CLS-1: classes are for active members. Non-members see the invitation
    // rather than an empty grid.
    if (user != null && !user.isActive) {
      return _PreviewCard(
        title: l.accountClassesPreviewTitle,
        onViewAll: null,
        child: NHEmptyState(
          message: l.classesLockedBody,
          icon: Icons.lock_outline,
          minHeight: 120,
          action: PrimaryButton(
            label: l.accountChoosePlan,
            expand: false,
            height: 48,
            onPressed: () => context.go(Routes.plans),
          ),
        ),
      );
    }

    return _PreviewCard(
      title: l.accountClassesPreviewTitle,
      onViewAll: () => context.go(Routes.accountClasses),
      child: AsyncSection(
        value: classes,
        minHeight: 120,
        onRetry: () => ref.invalidate(publishedClassesProvider),
        data: (list) {
          if (list.isEmpty) {
            return NHEmptyState(
              message: l.classesEmpty,
              icon: Icons.play_circle_outline,
              minHeight: 120,
            );
          }
          return Column(
            children: [
              for (final item in list.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClassListTile(
                    item: item,
                    onTap: () =>
                        context.go('${Routes.accountClasses}/${item.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// PRD section 7.6 item 6: "Payment history preview (last 3) →
/// `/account/payments`".
class _PaymentsPreview extends ConsumerWidget {
  const _PaymentsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final requests = ref.watch(myRecentPaymentsProvider);

    return _PreviewCard(
      title: l.accountPaymentsPreviewTitle,
      onViewAll: () => context.go(Routes.accountPayments),
      child: AsyncSection<List<PaymentRequest>>(
        value: requests,
        minHeight: 110,
        onRetry: () => ref.invalidate(myRecentPaymentsProvider),
        data: (list) {
          if (list.isEmpty) {
            return NHEmptyState(
              message: l.paymentsEmpty,
              icon: Icons.receipt_long_outlined,
              minHeight: 110,
            );
          }
          return Column(
            children: [
              for (final request in list.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PaymentRequestTile(request: request),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.title,
    required this.child,
    required this.onViewAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return NHCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: NHText.display(size: 24),
                ),
              ),
              if (onViewAll != null)
                NHTextLink(
                  label: L.of(context).actionViewAll,
                  onPressed: onViewAll,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
