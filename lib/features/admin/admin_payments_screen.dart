import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/widgets/chip_row.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';
import 'admin_payment_row.dart';
import 'admin_providers.dart';
import 'admin_shell.dart';

/// `/admin/payments` — PRD section 7.10.
///
/// Pending is a live listener, because the whole job is noticing a payment as
/// soon as it lands; Approved and Rejected are paged 20 at a time
/// (PRD section 13).
class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  PaymentStatus _tab = PaymentStatus.pending;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return AdminShell(
      title: l.adminPaymentsTitle,
      children: [
        FadeUp(
          index: 1,
          child: ChipRow(
            labels: [l.adminTabPending, l.adminTabApproved, l.adminTabRejected],
            selectedIndex: switch (_tab) {
              PaymentStatus.pending => 0,
              PaymentStatus.approved => 1,
              PaymentStatus.rejected => 2,
            },
            onSelected: (index) => setState(() => _tab = switch (index) {
              1 => PaymentStatus.approved,
              2 => PaymentStatus.rejected,
              _ => PaymentStatus.pending,
            }),
          ),
        ),
        const SizedBox(height: 18),
        if (_tab == PaymentStatus.pending)
          const _PendingList()
        else
          // A fresh key per tab restarts the pager instead of mixing pages.
          _ReviewedList(key: ValueKey(_tab), status: _tab),
      ],
    );
  }
}

class _PendingList extends ConsumerWidget {
  const _PendingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final pending = ref.watch(pendingPaymentsProvider);

    return AsyncSection<List<PaymentRequest>>(
      value: pending,
      onRetry: () => ref.invalidate(pendingPaymentsProvider),
      data: (list) => list.isEmpty
          ? NHEmptyState(
              message: l.adminNoPending,
              icon: Icons.inbox_outlined,
            )
          : _RowsWithDuplicateCheck(
              requests: list,
              onReviewed: () => invalidateAdminData(ref),
            ),
    );
  }
}

class _ReviewedList extends ConsumerStatefulWidget {
  const _ReviewedList({super.key, required this.status});

  final PaymentStatus status;

  @override
  ConsumerState<_ReviewedList> createState() => _ReviewedListState();
}

class _ReviewedListState extends ConsumerState<_ReviewedList> {
  final _requests = <PaymentRequest>[];

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({bool first = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await ref.read(paymentRepositoryProvider).fetchByStatusPage(
            status: widget.status,
            startAfter: first ? null : _cursor,
          );
      if (!mounted) return;
      setState(() {
        if (first) _requests.clear();
        _requests.addAll(page.requests);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.isOffline
            ? L.of(context).stateNoInternet
            : L.of(context).stateGenericError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    if (_error != null) {
      return NHErrorState(message: _error!, onRetry: () => _load(first: true));
    }
    if (_loading && _requests.isEmpty) return const NHLoading();
    if (_requests.isEmpty) {
      return NHEmptyState(message: l.stateNothingHere, icon: Icons.inbox_outlined);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RowsWithDuplicateCheck(requests: _requests, onReviewed: null),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GhostButton(
              label: l.paymentsLoadMore,
              expand: true,
              loading: _loading,
              onPressed: _loading ? null : _load,
            ),
          ),
      ],
    );
  }
}

/// Looks up which of the listed UTRs appear on more than one request, then
/// renders the rows (PRD section 7.10, duplicate UTR warning).
///
/// One `whereIn` query covers a whole page, and it only re-runs when the set of
/// UTRs on screen actually changes.
class _RowsWithDuplicateCheck extends ConsumerStatefulWidget {
  const _RowsWithDuplicateCheck({required this.requests, required this.onReviewed});

  final List<PaymentRequest> requests;
  final VoidCallback? onReviewed;

  @override
  ConsumerState<_RowsWithDuplicateCheck> createState() =>
      _RowsWithDuplicateCheckState();
}

class _RowsWithDuplicateCheckState
    extends ConsumerState<_RowsWithDuplicateCheck> {
  Set<String> _duplicates = const {};
  Set<String> _checkedRefs = const {};

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(_RowsWithDuplicateCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  Future<void> _check() async {
    final refs = {
      for (final request in widget.requests)
        if (request.upiRef != null) request.upiRef!,
    };
    if (refs.length == _checkedRefs.length &&
        refs.containsAll(_checkedRefs)) {
      return;
    }
    _checkedRefs = refs;
    if (refs.isEmpty) {
      if (_duplicates.isNotEmpty) setState(() => _duplicates = const {});
      return;
    }

    try {
      final duplicates =
          await ref.read(paymentRepositoryProvider).findDuplicateUtrs(refs);
      if (mounted) setState(() => _duplicates = duplicates);
    } on RepositoryException {
      // The warning is a convenience; losing it must not break the list.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.requests.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FadeUp(
              index: i < 6 ? i + 2 : 0,
              child: AdminPaymentRow(
                request: widget.requests[i],
                duplicateUtr: widget.requests[i].upiRef != null &&
                    _duplicates.contains(widget.requests[i].upiRef),
                onReviewed: widget.onReviewed,
              ),
            ),
          ),
      ],
    );
  }
}
