import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/responsive.dart';
import '../../core/validators.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nh_buttons.dart';
import '../../core/widgets/nh_card.dart';
import '../../core/widgets/nh_text_field.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/states.dart';
import '../../data/models/payment_request.dart';
import '../../data/repositories/firebase_providers.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import '../plans/order_summary.dart';
import '../plans/pending_notice.dart';
import '../plans/plan_selection.dart';
import 'upi_block.dart';

/// `/checkout` — PRD section 7.4.
///
/// Phase 1 has no payment gateway, so the member pays out of band (UPI or cash
/// at the desk) and the gym approves the request by hand. The app therefore
/// never asks for a PIN, a card number or a bank password (PRD PAY-4).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.planIdFromQuery, this.withPtFromQuery});

  final String? planIdFromQuery;
  final bool? withPtFromQuery;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _utr = TextEditingController();

  PaymentMethod _method = PaymentMethod.upi;
  bool _busy = false;
  String? _utrError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // PRD PAY-5: coming back from login must restore the same selection, which
    // arrives in the query string.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(planSelectionProvider.notifier).seedFromQuery(
            planId: widget.planIdFromQuery,
            withPT: widget.withPtFromQuery,
          );
    });
  }

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _submit(PricedSelection priced) async {
    final l = L.of(context);
    final member = ref.read(currentUserProvider).value;
    if (member == null) return;

    // PRD PAY-3: the UTR must be 12 digits. The rules re-check this.
    if (_method == PaymentMethod.upi && !Validate.utr(_utr.text)) {
      setState(() => _utrError = l.checkoutUtrError);
      return;
    }

    setState(() {
      _busy = true;
      _utrError = null;
      _submitError = null;
    });

    try {
      await ref.read(paymentRepositoryProvider).submit(
            draft: priced.draft,
            member: member,
            method: _method,
            upiRef: _method == PaymentMethod.upi ? _utr.text.trim() : null,
          );
      if (mounted) context.go(Routes.checkoutSubmitted);
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitError = error.isOffline
            ? l.stateNoInternet
            : l.checkoutSubmitFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final priced = ref.watch(pricedSelectionProvider);
    final plans = ref.watch(activePlansProvider);
    final settings = ref.watch(settingsProvider);
    // PRD PAY-1: only one request may be waiting at a time.
    final hasPending = ref.watch(myPendingPaymentProvider) != null;

    return NHScaffold(
      children: [
        ContentWidth(
          padVertical: const EdgeInsets.only(top: 34, bottom: 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeUp(
                index: 0,
                child: SectionTitle(
                  title: l.checkoutTitle,
                  subtitle: priced == null
                      ? null
                      : l.checkoutPayingFor(priced.plan.name),
                ),
              ),
              const SizedBox(height: 22),
              if (hasPending)
                const FadeUp(index: 1, child: PendingRequestNotice())
              else if (plans.hasError || settings.hasError)
                NHErrorState(
                  message: l.homePricesError,
                  onRetry: () {
                    ref.invalidate(activePlansProvider);
                    ref.invalidate(settingsProvider);
                  },
                )
              else if (priced == null)
                const NHLoading()
              else
                _CheckoutBody(
                  priced: priced,
                  method: _method,
                  onMethodChanged: (method) => setState(() {
                    _method = method;
                    _utrError = null;
                  }),
                  utrController: _utr,
                  utrError: _utrError,
                  onUtrChanged: () {
                    if (_utrError != null) setState(() => _utrError = null);
                  },
                  submitError: _submitError,
                  busy: _busy,
                  onSubmit: () => _submit(priced),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckoutBody extends StatelessWidget {
  const _CheckoutBody({
    required this.priced,
    required this.method,
    required this.onMethodChanged,
    required this.utrController,
    required this.utrError,
    required this.onUtrChanged,
    required this.submitError,
    required this.busy,
    required this.onSubmit,
  });

  final PricedSelection priced;
  final PaymentMethod method;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final TextEditingController utrController;
  final String? utrError;
  final VoidCallback onUtrChanged;
  final String? submitError;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final upiMissing =
        method == PaymentMethod.upi && !priced.settings.hasUpiId;

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodPicker(selected: method, onChanged: onMethodChanged),
        const SizedBox(height: 18),
        NHCard(
          padding: const EdgeInsets.all(20),
          child: switch (method) {
            PaymentMethod.upi => upiMissing
                ? InlineNotice(
                    message: l.checkoutUpiNotSetUp,
                    color: NHColors.yellow,
                    icon: Icons.info_outline,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UpiBlock(
                        settings: priced.settings,
                        total: priced.total,
                        planName: priced.plan.name,
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 18),
                      NHTextField(
                        label: l.checkoutUtrLabel,
                        controller: utrController,
                        helper: l.checkoutUtrHelp,
                        errorText: utrError,
                        keyboardType: TextInputType.number,
                        digitsOnly: true,
                        maxLength: 12,
                        prefixIcon: Icons.confirmation_number_outlined,
                        onChanged: (_) => onUtrChanged(),
                      ),
                    ],
                  ),
            PaymentMethod.cash => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 26, color: NHColors.red),
                  const SizedBox(height: 12),
                  Text(
                    l.checkoutCashText(formatRupees(priced.total)),
                    style: NHText.body(size: 15.5, color: NHColors.muted),
                  ),
                ],
              ),
          },
        ),
        const SizedBox(height: 16),
        // PRD PAY-4.
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, size: 17, color: NHColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.checkoutNoPinNote,
                style: NHText.body(size: 13, color: NHColors.muted),
              ),
            ),
          ],
        ),
      ],
    );

    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (submitError != null) ...[
          InlineNotice(message: submitError!),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: method == PaymentMethod.upi
              ? l.checkoutIHavePaid(formatRupees(priced.total))
              : l.checkoutSubmitRequest,
          loading: busy,
          onPressed: upiMissing ? null : onSubmit,
        ),
      ],
    );

    final right = OrderSummaryCard(
      priced: priced,
      action: action,
      showOffer: priced.offersFreePt,
    );

    if (context.bp.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: FadeUp(index: 1, child: left)),
          const SizedBox(width: 26),
          Expanded(flex: 5, child: FadeUp(index: 2, child: right)),
        ],
      );
    }

    return Column(
      children: [
        FadeUp(index: 1, child: left),
        const SizedBox(height: 22),
        FadeUp(index: 2, child: right),
      ],
    );
  }
}

/// PRD section 7.4: UPI (default) and Pay at gym (cash) work; Card and Net
/// banking are shown disabled with a "Coming soon" label, because they arrive
/// in Phase 2.
///
/// This replaces the UPI / Card / Net banking buttons in the mobile design
/// sample, as PRD section 7.4 states.
class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.selected, required this.onChanged});

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.checkoutMethodTitle, style: NHText.body(size: 16, weight: FontWeight.w600)),
        const SizedBox(height: 12),
        _MethodTile(
          label: l.checkoutMethodUpi,
          icon: Icons.qr_code_2_outlined,
          selected: selected == PaymentMethod.upi,
          onTap: () => onChanged(PaymentMethod.upi),
        ),
        const SizedBox(height: 10),
        _MethodTile(
          label: l.checkoutMethodCash,
          icon: Icons.payments_outlined,
          selected: selected == PaymentMethod.cash,
          onTap: () => onChanged(PaymentMethod.cash),
        ),
        const SizedBox(height: 10),
        _MethodTile(
          label: l.checkoutMethodCard,
          icon: Icons.credit_card_outlined,
          selected: false,
          onTap: null,
        ),
        const SizedBox(height: 10),
        _MethodTile(
          label: l.checkoutMethodNetBanking,
          icon: Icons.account_balance_outlined,
          selected: false,
          onTap: null,
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;

  /// Null marks the method as Phase 2.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final disabled = onTap == null;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Semantics(
        button: !disabled,
        enabled: !disabled,
        selected: selected,
        label: disabled ? '$label, ${l.stateComingSoon}' : label,
        child: ExcludeSemantics(
          child: NHCard(
            selected: selected,
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 21, color: selected ? NHColors.red : NHColors.muted),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: NHText.body(size: 16, weight: FontWeight.w600),
                  ),
                ),
                if (disabled)
                  Text(l.stateComingSoon, style: NHText.label(size: 11))
                else
                  _Radio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: NHMotion.hover,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? NHColors.red : Colors.transparent,
        border: Border.all(
          color: selected ? NHColors.red : NHColors.line,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
