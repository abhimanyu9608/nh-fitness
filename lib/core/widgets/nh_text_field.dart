import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// The app's one text field. Styling comes from the theme
/// (PRD section 5.3: `surface` fill, 2 px border, radius 14).
class NHTextField extends StatelessWidget {
  const NHTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.digitsOnly = false,
    this.autofillHints,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? maxLength;

  /// For the phone number and the 12-digit UTR (PRD PAY-3).
  final bool digitsOnly;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      enabled: enabled,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      style: NHText.body(size: 16),
      cursorColor: NHColors.red,
      inputFormatters: [
        if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        // The counter adds noise under every field; the helper text already
        // says "12 digits" where it matters.
        counterText: '',
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 19, color: NHColors.muted),
        suffixIcon: suffix,
      ),
    );
  }
}

/// A labelled on/off row, used by the add-on toggle and every admin switch.
class NHSwitchRow extends StatelessWidget {
  const NHSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.trailingLabel,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? subtitle;

  /// e.g. the price of the add-on, shown to the right of the label.
  final Widget? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged!(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: NHText.body(size: 16, weight: FontWeight.w600),
                            ),
                          ),
                          if (trailingLabel != null) ...[
                            const SizedBox(width: 10),
                            trailingLabel!,
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: NHText.body(size: 13.5, color: NHColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 44 px of height around the switch keeps the touch target
                // legal (PRD section 5.3).
                SizedBox(
                  height: NHSizes.minTouchTarget,
                  child: Center(
                    child: Switch(value: value, onChanged: onChanged),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
