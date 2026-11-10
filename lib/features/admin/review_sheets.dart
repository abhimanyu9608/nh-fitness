import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_providers.dart';

/// A bottom sheet in the app's style, capped so it reads as a panel on a wide
/// screen (PRD ADM-5: admin is web-first but must work on a phone).
Future<T?> showNHSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: NHColors.surface,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => Padding(
      // Keeps the content clear of the keyboard when a field is focused.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          child: builder(context),
        ),
      ),
    ),
  );
}

/// PRD section 7.10: "Approve opens a confirm sheet showing the start date
/// (default per ADM-2, editable) and end date (computed), then does the batch
/// write in ADM-1."
///
/// Returns true when the membership was activated.
Future<bool> showApproveSheet(
  BuildContext context,
  PaymentRequest request,
) async {
  final approved = await showNHSheet<bool>(
    context: context,
    builder: (context) => _ApproveSheet(request: request),
  );
  return approved ?? false;
}

class _ApproveSheet extends ConsumerStatefulWidget {
  const _ApproveSheet({required this.request});

  final PaymentRequest request;

  @override
  ConsumerState<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends ConsumerState<_ApproveSheet> {
  DateTime? _startDay;

  /// True when the member already has a membership running, so this one stacks
  /// on the end of it (PRD ADM-2).
  bool _isRenewal = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDefaultStart();
  }

  /// The default start date needs the member's `activeUntil`, so the sheet
  /// reads the profile once before it can offer a date.
  Future<void> _loadDefaultStart() async {
    try {
      final member =
          await ref.read(userRepositoryProvider).fetch(widget.request.uid);
      final activeUntil = member?.activeUntil;
      if (!mounted) return;
      setState(() {
        _startDay = approvalStartDay(activeUntil);
        _isRenewal =
            activeUntil != null && !istDayOf(activeUntil).isBefore(istToday());
        _loading = false;
      });
    } on RepositoryException {
      if (!mounted) return;
      setState(() {
        // Falling back to today still lets the admin approve; they can edit it.
        _startDay = istToday();
        _loading = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final current = _startDay ?? istToday();
    final civil = istCivil(current);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(civil.year, civil.month, civil.day),
      // A correction might need a past date; a start far in the future would
      // be a mistake.
      firstDate: DateTime(civil.year - 1),
      lastDate: DateTime(civil.year + 2),
    );
    if (picked == null) return;
    // The picker speaks the device's local time; memberships are stored at
    // 00:00 Asia/Kolkata (PRD section 8).
    setState(() => _startDay = istDay(picked.year, picked.month, picked.day));
  }

  Future<void> _approve() async {
    final startDay = _startDay;
    final adminUid = ref.read(currentUidProvider);
    if (startDay == null || adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).approve(
            request: widget.request,
            adminUid: adminUid,
            startDay: startDay,
          );
      invalidateAdminData(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on AlreadyReviewedException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = L.of(context).adminAlreadyReviewed;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).adminWriteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final request = widget.request;
    final startDay = _startDay;
    final endDay =
        startDay == null ? null : membershipEndDate(startDay, request.months);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.adminApproveTitle.toUpperCase(), style: NHText.display(size: 28)),
        const SizedBox(height: 8),
        Text(
          l.adminApproveBody(
            request.userName,
            request.planName,
            formatRupees(request.total),
          ),
          style: NHText.body(size: 15, color: NHColors.muted),
        ),
        const SizedBox(height: 18),
        if (_loading)
          const NHLoading(minHeight: 120)
        else ...[
          RaisedPanel(
            child: Column(
              children: [
                _DateRow(
                  label: l.adminApproveStartDate,
                  value: formatDate(startDay!),
                  onEdit: _pickStartDate,
                ),
                const Divider(height: 18),
                // PRD ADM-2: endDate = startDate + months − 1 day.
                _DateRow(
                  label: l.adminApproveEndDate,
                  value: formatDate(endDay!),
                  onEdit: null,
                ),
              ],
            ),
          ),
          if (_isRenewal) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: l.adminApproveRenewalNote,
              icon: Icons.autorenew_outlined,
              color: NHColors.yellow,
            ),
          ],
          if (request.upiRef != null) ...[
            const SizedBox(height: 12),
            Text(
              l.paymentsUtr(request.upiRef!),
              style: NHText.moneyBody(size: 14, color: NHColors.muted),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            InlineNotice(message: _error!),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: l.adminApproveConfirm,
            loading: _saving,
            onPressed: _approve,
          ),
          const SizedBox(height: 10),
          GhostButton(
            label: l.actionCancel,
            expand: true,
            height: 48,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, this.onEdit});

  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NHText.label(size: 11)),
              const SizedBox(height: 3),
              Text(value, style: NHText.body(size: 16, weight: FontWeight.w600)),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_calendar_outlined, size: 19),
            tooltip: L.of(context).actionEdit,
            constraints: const BoxConstraints(
              minWidth: NHSizes.minTouchTarget,
              minHeight: NHSizes.minTouchTarget,
            ),
          ),
      ],
    );
  }
}

/// PRD section 7.10: "Reject asks for a reason (required, e.g. 'Payment not
/// received') and sets `status: 'rejected'`."
Future<bool> showRejectSheet(
  BuildContext context,
  PaymentRequest request,
) async {
  final rejected = await showNHSheet<bool>(
    context: context,
    builder: (context) => _RejectSheet(request: request),
  );
  return rejected ?? false;
}

class _RejectSheet extends ConsumerStatefulWidget {
  const _RejectSheet({required this.request});

  final PaymentRequest request;

  @override
  ConsumerState<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends ConsumerState<_RejectSheet> {
  final _reason = TextEditingController();

  bool _saving = false;
  String? _reasonError;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _reject() async {
    final adminUid = ref.read(currentUidProvider);
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _reasonError = L.of(context).adminRejectReasonRequired);
      return;
    }
    if (adminUid == null) return;

    setState(() {
      _saving = true;
      _error = null;
      _reasonError = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).reject(
            requestId: widget.request.id,
            adminUid: adminUid,
            reason: reason,
          );
      invalidateAdminData(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on AlreadyReviewedException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = L.of(context).adminAlreadyReviewed;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).adminWriteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final request = widget.request;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.adminRejectTitle.toUpperCase(),
          style: NHText.display(size: 28, color: NHColors.danger),
        ),
        const SizedBox(height: 8),
        Text(
          l.adminApproveBody(
            request.userName,
            request.planName,
            formatRupees(request.total),
          ),
          style: NHText.body(size: 15, color: NHColors.muted),
        ),
        const SizedBox(height: 18),
        NHTextField(
          label: l.adminRejectReasonLabel,
          hint: l.adminRejectReasonHint,
          controller: _reason,
          errorText: _reasonError,
          maxLines: 3,
          autofocus: true,
          onChanged: (_) {
            if (_reasonError != null) setState(() => _reasonError = null);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          InlineNotice(message: _error!),
        ],
        const SizedBox(height: 20),
        DangerButton(
          label: l.adminRejectConfirm,
          expand: true,
          loading: _saving,
          onPressed: _reject,
        ),
        const SizedBox(height: 10),
        GhostButton(
          label: l.actionCancel,
          expand: true,
          height: 48,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
