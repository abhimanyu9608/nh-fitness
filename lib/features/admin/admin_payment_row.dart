import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_pill.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../l10n/app_localizations.dart';
import 'review_sheets.dart';

/// PRD section 7.10: "Row: member name, phone, plan, add-on, total, method,
/// UTR, submitted date" with Approve and Reject on the pending ones.
class AdminPaymentRow extends ConsumerWidget {
  const AdminPaymentRow({
    super.key,
    required this.request,
    required this.duplicateUtr,
    this.onReviewed,
  });

  final PaymentRequest request;

  /// PRD section 7.10: "if another request has the same `upiRef`, show a red
  /// 'UTR already used' warning on the row."
  final bool duplicateUtr;

  final VoidCallback? onReviewed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final months = request.months == 1
        ? l.plansMonthsOne
        : l.plansMonthsOther('${request.months}');

    return NHCard(
      padding: const EdgeInsets.all(16),
      borderColor: duplicateUtr ? NHColors.danger : null,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            request.userName.isEmpty
                                ? l.adminNavMembers
                                : request.userName,
                            style: NHText.display(size: 24),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Straight to the member's full history.
                        IconButton(
                          onPressed: () => context
                              .go('${Routes.adminMembers}/${request.uid}'),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          tooltip: l.adminMemberDetailTitle,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: NHSizes.minTouchTarget,
                            minHeight: NHSizes.minTouchTarget,
                          ),
                        ),
                      ],
                    ),
                    if (request.userPhone.isNotEmpty)
                      PhoneLine(phone: request.userPhone),
                    const SizedBox(height: 8),
                    Text(
                      [
                        l.paymentsPlanLine(request.planName, months),
                        if (request.withPT) l.paymentsWithPt,
                      ].join(' · '),
                      style: NHText.body(size: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        request.method == PaymentMethod.cash
                            ? l.paymentsMethodCash
                            : l.paymentsMethodUpi,
                        if (request.createdAt != null)
                          formatDateTime(request.createdAt!),
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
                    style: NHText.money(size: 30),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    l.paymentsUtr(request.upiRef!),
                    style: NHText.moneyBody(size: 14, color: NHColors.muted),
                  ),
                ),
                if (duplicateUtr)
                  StatusPill(label: l.adminDuplicateUtr, kind: PillKind.danger),
              ],
            ),
          ],
          if (request.rejectReason != null) ...[
            const SizedBox(height: 10),
            Text(
              l.accountRejectedReason(request.rejectReason!),
              style: NHText.body(size: 13.5, color: NHColors.danger),
            ),
          ],
          // PRD ADM-3: approve and reject only apply to pending requests.
          if (request.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                SmallButton(
                  label: l.adminApprove,
                  icon: Icons.check,
                  onPressed: () async {
                    final done = await showApproveSheet(context, request);
                    if (done) {
                      onReviewed?.call();
                      if (context.mounted) {
                        showNHSnack(context, l.adminApproved);
                      }
                    }
                  },
                ),
                const SizedBox(width: 10),
                SmallButton(
                  label: l.adminReject,
                  color: NHColors.surface2,
                  onPressed: () async {
                    final done = await showRejectSheet(context, request);
                    if (done) {
                      onReviewed?.call();
                      if (context.mounted) {
                        showNHSnack(context, l.adminRejected);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A phone number with a copy button — PRD section 7.10 asks for it on the
/// expiring list, and it is just as useful on a payment row.
class PhoneLine extends StatelessWidget {
  const PhoneLine({super.key, required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.call_outlined, size: 15, color: NHColors.muted),
        const SizedBox(width: 6),
        Text(
          phone,
          style: NHText.moneyBody(size: 14, color: NHColors.muted),
        ),
        IconButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: phone));
            if (context.mounted) {
              showNHSnack(context, l.stateCopiedToClipboard);
            }
          },
          icon: const Icon(Icons.copy_outlined, size: 15),
          tooltip: l.actionCopy,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(
            minWidth: NHSizes.minTouchTarget,
            minHeight: NHSizes.minTouchTarget,
          ),
        ),
      ],
    );
  }
}
