/// Field rules from PRD sections 7.4 and 7.5, in one place so the register
/// screen, the profile screen and the admin forms all agree.
abstract final class Validate {
  /// Deliberately loose: the job here is to catch typos like a missing `@`,
  /// not to out-guess the email standard. Firebase has the final say.
  static bool email(String value) {
    final trimmed = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s.]+\.[^@\s]+$').hasMatch(trimmed);
  }

  /// PRD section 7.5: at least 8 characters.
  static bool password(String value) => value.length >= 8;

  /// PRD section 7.5: 10 digits, optional but recommended.
  static bool phone(String value) =>
      RegExp(r'^[0-9]{10}$').hasMatch(digitsOnly(value));

  /// PRD PAY-3: the UPI reference number is exactly 12 digits. The same
  /// pattern is enforced server-side by the rules in PRD section 9.
  static bool utr(String value) => RegExp(r'^[0-9]{12}$').hasMatch(value.trim());

  /// PRD section 7.10: a plan id is used as a Firestore document id, so keep it
  /// to characters that read well in a URL and cannot break a path.
  static bool planId(String value) =>
      RegExp(r'^[a-z0-9_]{2,40}$').hasMatch(value.trim());

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}
