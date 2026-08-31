import 'package:flutter_test/flutter_test.dart';

import 'package:admin_arawatan/core/admin_driver_route_params.dart';

void main() {
  group('AdminDriverRouteParams.parseUserId', () {
    test('bare uid', () {
      expect(
        AdminDriverRouteParams.parseUserId('DZbM2HXJeNTCwiVUtahiaT79paH2'),
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
      );
    });

    test('user|uid must not resolve as collection name only', () {
      expect(
        AdminDriverRouteParams.parseUserId('user|DZbM2HXJeNTCwiVUtahiaT79paH2'),
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
      );
    });

    test('encoded user|uid deep link', () {
      expect(
        AdminDriverRouteParams.parseUserId(
          'user%7CDZbM2HXJeNTCwiVUtahiaT79paH2',
        ),
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
      );
    });

    test('user/uid path form', () {
      expect(
        AdminDriverRouteParams.parseUserId(
          'user/DZbM2HXJeNTCwiVUtahiaT79paH2',
        ),
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
      );
      expect(
        AdminDriverRouteParams.parseUserId(
          '/user/DZbM2HXJeNTCwiVUtahiaT79paH2',
        ),
        'DZbM2HXJeNTCwiVUtahiaT79paH2',
      );
    });

    test('missing / empty / invalid → null', () {
      expect(AdminDriverRouteParams.parseUserId(null), isNull);
      expect(AdminDriverRouteParams.parseUserId(''), isNull);
      expect(AdminDriverRouteParams.parseUserId('   '), isNull);
      expect(AdminDriverRouteParams.parseUserId('user'), isNull);
      expect(AdminDriverRouteParams.parseUserId('user|'), isNull);
      expect(AdminDriverRouteParams.parseUserId('user|user'), isNull);
    });
  });

  group('review / profile loader contract (param only)', () {
    test('profile refresh-safe: same uid from list and deep link forms', () {
      const uid = '0cHx6QJ2ljZRv8aayR0rLQDDD4x1';
      expect(AdminDriverRouteParams.parseUserId(uid), uid);
      expect(AdminDriverRouteParams.parseUserId('user|$uid'), uid);
      expect(AdminDriverRouteParams.parseUserId('user/$uid'), uid);
    });

    test('invalid param surfaces as null (UI: invalid state)', () {
      expect(AdminDriverRouteParams.parseUserId(null), isNull);
      expect(AdminDriverRouteParams.parseUserId(''), isNull);
    });
  });
}
