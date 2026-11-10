import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_settings.dart';
import '../../l10n/app_localizations.dart';

/// PRD section 7.4: the UPI deep link the QR encodes and the "Pay with UPI
/// app" button opens.
///
///     upi://pay?pa={upiId}&pn={upiName}&am={total}&cu=INR&tn=NH Fitness {planName}
///
/// Built through [Uri] so the plan name and the payee name are percent-encoded
/// — a gym called "Gold's Gym & Fitness" would otherwise break the link.
Uri buildUpiUri({
  required AppSettings settings,
  required int total,
  required String planName,
}) {
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': settings.upiId,
      'pn': settings.upiName,
      'am': '$total',
      'cu': 'INR',
      'tn': 'NH Fitness $planName',
    },
  );
}

/// The QR code, the UPI ID with a Copy button, and — on Android — a button
/// that hands the same link to an installed UPI app (PRD section 7.4).
class UpiBlock extends StatefulWidget {
  const UpiBlock({
    super.key,
    required this.settings,
    required this.total,
    required this.planName,
  });

  final AppSettings settings;
  final int total;
  final String planName;

  @override
  State<UpiBlock> createState() => _UpiBlockState();
}

class _UpiBlockState extends State<UpiBlock> {
  /// Null until we have asked the platform whether a UPI app exists.
  ///
  /// PRD section 7.4 step 3: show the button on Android, and hide it on web
  /// and iOS if the link cannot be opened.
  bool? _canOpenUpiApp;

  @override
  void initState() {
    super.initState();
    _checkUpiApp();
  }

  Future<void> _checkUpiApp() async {
    if (kIsWeb) {
      setState(() => _canOpenUpiApp = false);
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) {
      setState(() => _canOpenUpiApp = false);
      return;
    }
    bool can;
    try {
      can = await canLaunchUrl(_uri);
    } on Exception {
      can = false;
    }
    if (mounted) setState(() => _canOpenUpiApp = can);
  }

  Uri get _uri => buildUpiUri(
    settings: widget.settings,
    total: widget.total,
    planName: widget.planName,
  );

  Future<void> _copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: widget.settings.upiId));
    if (mounted) showNHSnack(context, L.of(context).checkoutUpiIdCopied);
  }

  Future<void> _openUpiApp() async {
    bool opened;
    try {
      opened = await launchUrl(_uri, mode: LaunchMode.externalApplication);
    } on Exception {
      opened = false;
    }
    if (!opened && mounted) {
      showNHSnack(context, L.of(context).checkoutUpiAppFailed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.checkoutUpiScanHint(formatRupees(widget.total)),
          style: NHText.body(size: 15, color: NHColors.muted),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // A QR has to sit on white to scan reliably.
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: QrImageView(
              data: _uri.toString(),
              size: 200,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              // Scanners cope with a damaged code better at this level.
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              semanticsLabel: l.checkoutUpiScanHint(formatRupees(widget.total)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        RaisedPanel(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.checkoutUpiIdLabel, style: NHText.label(size: 11)),
                    const SizedBox(height: 3),
                    Text(
                      widget.settings.upiId,
                      style: NHText.body(size: 16, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _copyUpiId,
                icon: const Icon(Icons.copy_outlined, size: 19),
                tooltip: l.actionCopy,
                constraints: const BoxConstraints(
                  minWidth: NHSizes.minTouchTarget,
                  minHeight: NHSizes.minTouchTarget,
                ),
              ),
            ],
          ),
        ),
        if (_canOpenUpiApp ?? false) ...[
          const SizedBox(height: 14),
          GhostButton(
            label: l.checkoutPayWithUpiApp,
            icon: Icons.open_in_new,
            expand: true,
            onPressed: _openUpiApp,
          ),
        ],
      ],
    );
  }
}
