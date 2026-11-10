import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';

/// PRD PAY-1: "A member can have only one pending request at a time. If one
/// exists, `/plans` and `/checkout` show 'You already have a request waiting
/// for approval' with a link to `/account`."
///
/// Renders nothing when there is no pending request, so both screens can place
/// it unconditionally.
class PendingRequestNotice extends ConsumerWidget {
  const PendingRequestNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(myPendingPaymentProvider);
    if (pending == null) return const SizedBox.shrink();
    return _Notice(request: pending);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.request});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return NHCard(
      borderColor: NHColors.yellow,
      background: NHColors.surface2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.checkoutPendingExists,
                  style: NHText.display(size: 24, color: NHColors.yellow),
                ),
              ),
              StatusPill(label: l.accountStatusPending, kind: PillKind.pending),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.checkoutPendingExistsBody,
            style: NHText.body(size: 15, color: NHColors.muted),
          ),
          const SizedBox(height: 14),
          DetailRow(
            label: request.planName,
            value: formatRupees(request.total),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              label: l.submittedGoToAccount,
              height: 48,
              onPressed: () => context.go('/account'),
            ),
          ),
        ],
      ),
    );
  }
}
