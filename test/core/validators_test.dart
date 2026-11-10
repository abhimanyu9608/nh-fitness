import 'package:flutter_test/flutter_test.dart';
import 'package:nh_fitness/core/validators.dart';

void main() {
  group('email', () {
    test('accepts ordinary addresses', () {
      expect(Validate.email('ravi@example.com'), isTrue);
      expect(Validate.email('  ravi.kumar+gym@example.co.in  '), isTrue);
    });

    test('rejects obvious typos', () {
      expect(Validate.email(''), isFalse);
      expect(Validate.email('ravi'), isFalse);
      expect(Validate.email('ravi@example'), isFalse);
      expect(Validate.email('ravi@@example.com'), isFalse);
      expect(Validate.email('ravi example@test.com'), isFalse);
    });
  });

  group('password (PRD section 7.5)', () {
    test('needs at least 8 characters', () {
      expect(Validate.password('1234567'), isFalse);
      expect(Validate.password('12345678'), isTrue);
    });
  });

  group('phone (PRD section 7.5)', () {
    test('accepts exactly 10 digits', () {
      expect(Validate.phone('9876543210'), isTrue);
      // Digits are extracted first, so spacing and +91 are fine.
      expect(Validate.phone('98765 43210'), isTrue);
    });

    test('rejects the wrong number of digits', () {
      expect(Validate.phone('98765'), isFalse);
      expect(Validate.phone('98765432101'), isFalse);
      expect(Validate.phone(''), isFalse);
    });
  });

  group('utr (PRD PAY-3)', () {
    test('accepts exactly 12 digits', () {
      expect(Validate.utr('123456789012'), isTrue);
      expect(Validate.utr('  123456789012 '), isTrue);
    });

    test('rejects anything else', () {
      expect(Validate.utr('12345678901'), isFalse);
      expect(Validate.utr('1234567890123'), isFalse);
      expect(Validate.utr('12345678901a'), isFalse);
      expect(Validate.utr(''), isFalse);
    });
  });

  group('planId', () {
    test('accepts the seed ids from PRD section 8.2', () {
      expect(Validate.planId('monthly'), isTrue);
      expect(Validate.planId('half_yearly'), isTrue);
    });

    test('rejects ids that would not survive a URL or a path', () {
      expect(Validate.planId('Monthly'), isFalse);
      expect(Validate.planId('half yearly'), isFalse);
      expect(Validate.planId('a'), isFalse);
      expect(Validate.planId('plan/1'), isFalse);
    });
  });

  test('digitsOnly strips everything else', () {
    expect(Validate.digitsOnly('+91 98765-43210'), '919876543210');
    expect(Validate.digitsOnly('abc'), '');
  });
}
