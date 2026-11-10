import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../data/models/payment_request.dart';
import '../../l10n/app_localizations.dart';

/// One payment request as a row: "date, plan, total, method, status pill, UTR,
/// rejection reason if any" (PRD section 7.8).
///
/// Shared by the dashboard preview, `/account/payments` and the admin's member
/// detail screen, so a payment reads the same wherever it appears.
class PaymentRequestTile extends StatelessWidget {
  const PaymentRequestTile({super.key, required this.request, this.trailing});

  final PaymentRequest request;

  /// Approve/Reject buttons, when an admin is looking at it.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final months = request.months == 1
        ? l.plansMonthsOne
        : l.plansMonthsOther('${request.months}');

    return NHCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.paymentsPlanLine(request.planName, months),
                      style: NHText.body(size: 16, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (request.createdAt != null)
                          formatDateTime(request.createdAt!),
                        request.method == PaymentMethod.cash
                            ? l.paymentsMethodCash
                            : l.paymentsMethodUpi,
                        if (request.withPT) l.paymentsWithPt,
                      ].join(' · '),
                      style: NHText.body(size: 13.5, color: NHColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupees(request.total),
                    style: NHText.moneyBody(size: 17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  StatusPill(
                    label: switch (request.status) {
                      PaymentStatus.pending => l.accountStatusPending,
                      PaymentStatus.approved => l.accountStatusApproved,
                      PaymentStatus.rejected => l.accountStatusRejected,
                    },
                    kind: switch (request.status) {
                      PaymentStatus.pending => PillKind.pending,
                      PaymentStatus.approved => PillKind.success,
                      PaymentStatus.rejected => PillKind.danger,
                    },
                  ),
                ],
              ),
            ],
          ),
          if (request.upiRef != null) ...[
            const SizedBox(height: 10),
            Text(
              l.paymentsUtr(request.upiRef!),
              style: NHText.moneyBody(size: 13, color: NHColors.muted),
            ),
          ],
          if (request.rejectReason != null) ...[
            const SizedBox(height: 10),
            Text(
              l.accountRejectedReason(request.rejectReason!),
              style: NHText.body(size: 13.5, color: NHColors.danger),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 14), trailing!],
        ],
      ),
    );
  }
}
