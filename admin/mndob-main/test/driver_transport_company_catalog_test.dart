import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mndob/core/driver_transport_company_catalog.dart';

class _DocRef extends Fake implements DocumentReference<Map<String, dynamic>> {
  _DocRef(this._path);

  final String _path;

  @override
  String get path => _path;

  @override
  String get id => _path.split('/').last;
}

void main() {
  group('DriverTransportCompanyCatalog.matchesCountry', () {
    final sa = _DocRef('countries/SA');
    final kg = _DocRef('countries/KG');
    final saudiAlias = _DocRef('countries/country_sa');

    test('exact DocumentReference path matches', () {
      expect(
        DriverTransportCompanyCatalog.matchesCountry(
          {'Rev_dolh': sa},
          sa,
        ),
        isTrue,
      );
    });

    test('ISO alias ids match same country', () {
      expect(
        DriverTransportCompanyCatalog.matchesCountry(
          {'Rev_dolh': saudiAlias},
          sa,
        ),
        isTrue,
      );
    });

    test('string path matches', () {
      expect(
        DriverTransportCompanyCatalog.matchesCountry(
          {'Rev_dolh': 'countries/SA'},
          sa,
        ),
        isTrue,
      );
    });

    test('other country does not match', () {
      expect(
        DriverTransportCompanyCatalog.matchesCountry(
          {'Rev_dolh': kg},
          sa,
        ),
        isFalse,
      );
    });

    test('null country accepts all', () {
      expect(
        DriverTransportCompanyCatalog.matchesCountry(
          {'Rev_dolh': sa},
          null,
        ),
        isTrue,
      );
    });
  });

  group('DriverTransportCompanyCatalog.isActiveCompany', () {
    test('requires explicit active flag', () {
      expect(DriverTransportCompanyCatalog.isActiveCompany({}), isFalse);
      expect(
        DriverTransportCompanyCatalog.isActiveCompany({'actev': true}),
        isTrue,
      );
      expect(
        DriverTransportCompanyCatalog.isActiveCompany({'actev': false}),
        isFalse,
      );
    });
  });

  group('country filter for registration list', () {
    test('keeps only active companies in selected country', () {
      final sa = _DocRef('countries/SA');
      final kg = _DocRef('countries/KG');
      final rows = <Map<String, dynamic>>[
        {
          'id': 'sa_active',
          'naim': 'Riyadh Transport',
          'actev': true,
          'Rev_dolh': sa,
        },
        {
          'id': 'sa_inactive',
          'naim': 'Hidden Co',
          'actev': false,
          'Rev_dolh': sa,
        },
        {
          'id': 'kg_active',
          'naim': 'Bishkek Fleet',
          'actev': true,
          'Rev_dolh': kg,
        },
      ];

      final filtered = rows.where((data) {
        return DriverTransportCompanyCatalog.isActiveCompany(data) &&
            DriverTransportCompanyCatalog.matchesCountry(data, sa);
      }).toList();

      expect(filtered, hasLength(1));
      expect(filtered.first['id'], 'sa_active');
    });
  });
}
