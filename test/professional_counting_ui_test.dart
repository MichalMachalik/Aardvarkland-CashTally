import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';
import 'package:vycetka/l10n/platform_localizations.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/models/count_mode.dart';
import 'package:vycetka/screens/count_screen.dart';
import 'package:vycetka/services/entitlement_service.dart';
import 'package:vycetka/services/preference_service.dart';
import 'package:vycetka/state/app_controller.dart';
import 'package:vycetka/state/app_scope.dart';
import 'package:vycetka/widgets/denomination_row.dart';

void main() {
  testWidgets('tap multiplier accelerates entry and respects a locked count', (
    tester,
  ) async {
    final currency = CurrencyCatalog.byCode('CZK');
    final denomination = currency.banknotes.last;
    final changes = <int>[];

    await tester.pumpWidget(
      _materialHarness(
        child: DenominationRow(
          currency: currency,
          denomination: denomination,
          quantity: 0,
          step: 5,
          onChanged: changes.add,
          onEdit: () {},
        ),
      ),
    );
    await tester.tap(find.byType(DenominationRow));

    expect(changes, <int>[5]);

    await tester.pumpWidget(
      _materialHarness(
        child: DenominationRow(
          currency: currency,
          denomination: denomination,
          quantity: 7,
          enabled: false,
          step: 10,
          onChanged: changes.add,
          onEdit: () {},
        ),
      ),
    );
    await tester.tap(find.byType(DenominationRow));
    expect(changes, <int>[5]);
  });

  testWidgets('all quick steps work for card, plus, minus and long press', (
    tester,
  ) async {
    final currency = CurrencyCatalog.byCode('CZK');
    final denomination = currency.banknotes.last;

    for (final step in <int>[1, 10, 50, 100]) {
      var quantity = 0;
      await tester.pumpWidget(
        _materialHarness(
          child: StatefulBuilder(
            builder: (context, setState) => DenominationRow(
              key: ValueKey(step),
              currency: currency,
              denomination: denomination,
              quantity: quantity,
              step: step,
              onChanged: (value) => setState(() => quantity = value),
              onEdit: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DenominationRow));
      await tester.pump();
      expect(quantity, step);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump();
      expect(quantity, step * 2);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
      await tester.pump();
      expect(quantity, step);
      await tester.longPress(find.byType(DenominationRow));
      await tester.pump();
      expect(quantity, 0);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
      await tester.pump();
      expect(quantity, 0);
    }
  });

  testWidgets(
    'blind count hides comparison, blocks save and then locks quantities',
    (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        entitlementService: _AdFreeEntitlementService(),
        preferenceService: _MemoryPreferenceService(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: _materialHarness(
            child: const CountScreen(initialCurrencyCode: 'CZK'),
          ),
        ),
      );
      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(find.text('Expected amount (CZK)'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(
        find.text('Finish and lock the blind count before saving.'),
        findsOneWidget,
      );

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byType(DenominationRow), findsWidgets);
      await tester.tap(find.byType(DenominationRow).first);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Finish blind count'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Finish blind count'));
      await tester.pumpAndSettle();
      expect(find.text('Lock and continue'), findsOneWidget);
      await tester.tap(find.text('Lock and continue'));
      await tester.pumpAndSettle();

      expect(find.text('Expected amount (CZK)'), findsOneWidget);
      expect(
        tester.widgetList<DenominationRow>(find.byType(DenominationRow)),
        everyElement(predicate<DenominationRow>((row) => !row.enabled)),
      );
    },
  );

  testWidgets(
    'changing currency asks before clearing a signature without amounts',
    (tester) async {
      final controller = AppController(
        entitlementService: _AdFreeEntitlementService(),
        preferenceService: _MemoryPreferenceService(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: _materialHarness(
            child: CountScreen(
              existingSession: CashCountSession(
                id: 'test-signature',
                currencyCode: 'CZK',
                createdAt: DateTime(2026, 11, 15),
                mode: CountMode.professional,
                cashierSignaturePngBase64:
                    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
              ),
            ),
          ),
        ),
      );
      final dropdown = find.byType(DropdownButtonFormField<String>);
      Future<void> selectCurrency(String code) async {
        await tester.tap(dropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('$code ·').last);
        await tester.pumpAndSettle();
      }

      await selectCurrency('EUR');
      expect(find.text('Change currency?'), findsOneWidget);
      expect(find.textContaining('Cashier signature'), findsWidgets);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CZK ·'), findsOneWidget);

      await selectCurrency('EUR');
      expect(find.text('Change currency?'), findsOneWidget);
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(find.textContaining('EUR ·'), findsOneWidget);

      await selectCurrency('USD');
      expect(find.text('Change currency?'), findsNothing);
      expect(find.textContaining('USD ·'), findsOneWidget);
    },
  );

  testWidgets(
    'blank quantity keeps the old count and explicit zero clears it',
    (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        entitlementService: _AdFreeEntitlementService(),
        preferenceService: _MemoryPreferenceService(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: _materialHarness(
            child: const CountScreen(
              initialCurrencyCode: 'CZK',
              mode: CountMode.quick,
            ),
          ),
        ),
      );
      final row = find.byType(DenominationRow).first;
      await tester.ensureVisible(row);
      final add = find.descendant(of: row, matching: find.byTooltip('+'));
      await tester.tap(add);
      await tester.pump();
      await tester.tap(add);
      await tester.pumpAndSettle();
      final count = find.descendant(
        of: row,
        matching: find.widgetWithText(TextButton, '2'),
      );
      await tester.tap(count);
      await tester.pumpAndSettle();
      final input = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(input, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number of pieces.'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(count, findsOneWidget);

      await tester.tap(count);
      await tester.pumpAndSettle();
      await tester.enterText(input, '0');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.descendant(
          of: row,
          matching: find.widgetWithText(TextButton, '0'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('quick count omits professional closing fields', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      entitlementService: _AdFreeEntitlementService(),
      preferenceService: _MemoryPreferenceService(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: _materialHarness(
          child: const CountScreen(
            initialCurrencyCode: 'CZK',
            mode: CountMode.quick,
          ),
        ),
      ),
    );

    expect(find.text('Quick count'), findsOneWidget);
    expect(find.text('Expected amount (CZK)'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}

Widget _materialHarness({required Widget child}) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    AppMaterialFallbackLocalizationsDelegate(),
    AppCupertinoFallbackLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

class _AdFreeEntitlementService extends EntitlementService {
  static const snapshotValue = EntitlementSnapshot(
    kind: EntitlementKind.lifetime,
  );

  @override
  EntitlementSnapshot get snapshot => snapshotValue;

  @override
  Future<EntitlementSnapshot> initialize() async => snapshotValue;
}

class _MemoryPreferenceService extends PreferenceService {
  @override
  Future<void> saveCountryAndCurrency({
    required String countryId,
    required String currencyCode,
  }) async {}

  @override
  Future<void> saveCurrencyCode(String currencyCode) async {}
}
