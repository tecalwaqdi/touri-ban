import 'package:ara_oatan_app/app_state.dart';
import 'package:ara_oatan_app/core/toury_checkout_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('touryApplyBillableHours AUTO vs USER', () {
    late FFAppState app;

    setUp(() {
      app = FFAppState();
      app.saatcar = 1;
      app.userRequestedExtraHours = 0;
      app.addhors = 0;
      app.totalsaat = 1;
      app.osrmTotalTime = 0;
      app.Minimumhours = 0;
      app.DriverGuideState = false;
      app.cartmkss = [];
    });

    test('route auto 2h does not inflate userRequestedExtraHours', () {
      // Financial hours use a Google Routes quote, not a bare OSRM timer.
      app.routeProvider = 'google';
      app.routeDurationMinutes = 70; // ceil → 2h
      app.osrmTotalTime = 70;
      final r = touryApplyBillableHours(app);
      expect(r.billableHours, 2);
      expect(app.userRequestedExtraHours, 0);
      expect(app.addhors, 1); // display delta
      expect(app.totalsaat, 2);
    });

    test('explicit 4h preserved when auto drops after shorter route', () {
      app.userRequestedExtraHours = 3; // 1+3=4h requested
      app.routeProvider = 'google';
      app.routeDurationMinutes = 200; // auto high first
      app.osrmTotalTime = 200;
      touryApplyBillableHours(app);
      expect(app.totalsaat, greaterThanOrEqualTo(4));

      app.routeDurationMinutes = 40; // auto drops to 1h
      app.osrmTotalTime = 40;
      final r = touryApplyBillableHours(app);
      expect(app.userRequestedExtraHours, 3);
      expect(r.billableHours, 4);
      expect(app.totalsaat, 4);
    });

    test('auto reduction when user extras=0', () {
      app.userRequestedExtraHours = 0;
      app.routeProvider = 'google';
      app.routeDurationMinutes = 200; // ~4h
      app.osrmTotalTime = 200;
      touryApplyBillableHours(app);
      final high = app.totalsaat;
      expect(high, greaterThanOrEqualTo(3));

      app.routeDurationMinutes = 50; // 1h
      app.osrmTotalTime = 50;
      final r = touryApplyBillableHours(app);
      expect(r.billableHours, 1);
      expect(app.userRequestedExtraHours, 0);
    });
  });
}
