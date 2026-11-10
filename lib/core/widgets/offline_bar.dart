import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';

/// True when the device reports no network at all.
///
/// PRD section 13 asks for a "You are offline" bar. Firestore keeps serving
/// from its cache on mobile, so this is a hint, not a blocker — the app stays
/// usable and the bar simply explains why a list may be stale.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOffline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOffline);
});

bool _isOffline(List<ConnectivityResult> results) =>
    results.isEmpty || results.every((r) => r == ConnectivityResult.none);

/// A thin bar above the header. Takes no height while online.
class OfflineBar extends ConsumerWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A connectivity check that itself fails must not hide the app behind an
    // error, so anything other than a definite "offline" renders nothing.
    final offline = ref.watch(isOfflineProvider).value ?? false;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topCenter,
      child: offline
          ? Container(
              width: double.infinity,
              color: NHColors.surface2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 17, color: NHColors.yellow),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      L.of(context).stateOffline,
                      textAlign: TextAlign.center,
                      style: NHText.body(size: 13.5, color: NHColors.muted),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
