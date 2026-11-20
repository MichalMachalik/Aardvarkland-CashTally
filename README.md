# Aardvarkland CashTally

Offline cash-counting app for Android and iOS. Count by denomination, compare expected cash and export closing reports.

[Live Preview](https://michalmachalik.github.io/Aardvarkland-CashTally/) · [Open the counter](https://michalmachalik.github.io/Aardvarkland-CashTally/app/)

The preview uses sample data in the browser. Native file sharing, printing, app locking and platform storage are represented by browser alternatives.

To run the preview locally, serve `preview/` over HTTP and open `http://127.0.0.1:4173/`.

```sh
python -m http.server 4173 --bind 127.0.0.1 --directory preview
```

## What it does

- quick counts and full till closings
- 32 currencies and 36 interface languages
- denomination multipliers, custom denominations and till templates
- expected cash, variance, deposit and retained cash
- POS/EFTPOS CSV import and reconciliation
- local history with search and filters
- PDF, CSV and text reports with signatures and SHA-256 fingerprints
- encrypted backup and optional device app lock
- no ads, subscriptions or purchases in the default public build

## Run it

The [pinned Flutter SDK](.fvmrc) is 3.44.0 with Dart 3.12. Select an Android emulator, an attached device or an iOS simulator with `flutter devices`. iOS builds require macOS and Xcode.

```bash
git clone https://github.com/MichalMachalik/Aardvarkland-CashTally.git
cd Aardvarkland-CashTally
flutter pub get
flutter run
```

## Checks

The source validator reads the translation and build configuration files with Python and PyYAML. Run these checks from the project root after `flutter pub get`.

```bash
python -m pip install PyYAML
python scripts/verify_source.py
python scripts/test_native_patcher.py
flutter analyze
flutter test
```

GitHub Actions additionally runs Android encrypted-backup crash/restart
integration tests on an emulator. See
[Android recovery testing](docs/ANDROID_RECOVERY_TESTING.md) for coverage,
local execution and the physical-device checklist.

## Builds

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Sign release builds with your own Android keystore or Apple signing certificate; signing files are not included. Store transactions, biometrics, file pickers and printing need platform or device testing.

## Data

Amounts are stored as integer minor units. Reports, history and encrypted backups are created locally; the app does not require a server. Do not attach real till exports, signatures or business records to public issues.

- Security reports: [SECURITY.md](SECURITY.md)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)
