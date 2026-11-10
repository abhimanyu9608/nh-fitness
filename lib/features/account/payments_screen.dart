import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../l10n/app_localizations.dart';
import 'account_shell.dart';
import 'payment_row.dart';

/// `/account/payments` — PRD section 7.8: "list of the member's payment
/// requests, newest first … Paginate 20 per page."
///
/// Paging keeps the Spark plan's daily read budget intact (PRD section 13).
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _requests = <PaymentRequest>[];

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loading = true;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore(first: true);
  }

  Future<void> _loadMore({bool first = false}) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final page = await ref.read(paymentRepositoryProvider).fetchMinePage(
            uid: uid,
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

    return AccountShell(
      title: l.paymentsTitle,
      children: [
        if (_error != null)
          NHErrorState(message: _error!, onRetry: () => _loadMore(first: true))
        else if (_loading && _requests.isEmpty)
          const NHLoading()
        else if (_requests.isEmpty)
          NHEmptyState(
            message: l.paymentsEmpty,
            icon: Icons.receipt_long_outlined,
          )
        else ...[
          for (var i = 0; i < _requests.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FadeUp(
                // Only the first page animates in; later pages append quietly.
                index: i < pageSize ? (i + 1).clamp(1, 8) : 0,
                child: PaymentRequestTile(request: _requests[i]),
              ),
            ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GhostButton(
                label: l.paymentsLoadMore,
                expand: true,
                loading: _loading,
                onPressed: _loading ? null : _loadMore,
              ),
            ),
        ],
      ],
    );
  }
}
