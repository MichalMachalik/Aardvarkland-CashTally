# Aardvarkland CashTally

[Česká verze](#cesky)

Offline cash-counting app for Android and iOS. Count by denomination, compare expected cash and export closing reports.

[Live Preview](https://michalmachalik.github.io/Aardvarkland-CashTally/) · [Open the counter](https://michalmachalik.github.io/Aardvarkland-CashTally/app/) · [Android APK](https://github.com/MichalMachalik/Aardvarkland-CashTally/releases/latest)

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

The GitHub APK requires Android 7 or newer. It uses the package ID `cz.aardvarkland.cashtally` so it can coexist with earlier installations. To build an APK with that package ID, set `AARDVARKLAND_GITHUB_APK=1` before running `flutter build apk --release`.

## Data

Amounts are stored as integer minor units. Reports, history and encrypted backups are created locally; the app does not require a server. Do not attach real till exports, signatures or business records to public issues.

- Security reports: [SECURITY.md](SECURITY.md)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)

---

<a name="cesky"></a>

## Česká verze

Mobilní aplikace pro počítání hotovosti na Androidu a iOS funguje i offline. Obsluha spočítá hotovost podle nominálních hodnot, porovná ji s očekávaným stavem a vyexportuje uzávěrku.

[Veřejný náhled](https://michalmachalik.github.io/Aardvarkland-CashTally/) · [Otevřít počítadlo](https://michalmachalik.github.io/Aardvarkland-CashTally/app/) · [APK pro Android](https://github.com/MichalMachalik/Aardvarkland-CashTally/releases/latest)

Náhled používá ukázková data v prohlížeči. Sdílení souborů, tisk, zámek aplikace a ukládání dat mají v náhledu webové alternativy. Pro místní spuštění zpřístupněte adresář `preview/` přes HTTP a otevřete `http://127.0.0.1:4173/`.

```sh
python -m http.server 4173 --bind 127.0.0.1 --directory preview
```

### Funkce

- Rychlé přepočítání hotovosti a úplná pokladní uzávěrka.
- 32 měn a 36 jazyků rozhraní.
- Násobky nominálních hodnot, vlastní nominály a šablony pokladen.
- Výpočet očekávané hotovosti, rozdílu, odvodu a částky ponechané v pokladně.
- Import CSV z pokladen a platebních terminálů (POS/EFTPOS) a porovnání částek.
- Místní historie s vyhledáváním a filtry.
- Výstupy PDF, CSV a textové sestavy s podpisy a otisky SHA-256.
- Šifrovaná záloha a volitelný zámek aplikace na zařízení.
- Výchozí veřejná verze je bez reklam, předplatného a nákupů.

### Spuštění

Projekt používá [Flutter SDK 3.44.0](.fvmrc) s Dartem 3.12. Příkazem `flutter devices` vyberte emulátor Androidu, připojené zařízení nebo simulátor iOS. Pro sestavení na iOS potřebujete macOS a Xcode.

```bash
git clone https://github.com/MichalMachalik/Aardvarkland-CashTally.git
cd Aardvarkland-CashTally
flutter pub get
flutter run
```

### Ověření

Validátor kontroluje překlady a konfiguraci sestavení pomocí Pythonu a PyYAML. Po `flutter pub get` spusťte v kořeni projektu následující příkazy.

```bash
python -m pip install PyYAML
python scripts/verify_source.py
python scripts/test_native_patcher.py
flutter analyze
flutter test
```

GitHub Actions navíc na emulátoru Androidu ověřuje obnovu šifrované zálohy po pádu a restartu. Rozsah testů, místní spuštění a kontroly na fyzickém zařízení popisuje [testování obnovy na Androidu](docs/ANDROID_RECOVERY_TESTING.md).

### Sestavení

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Vydání podepište vlastním klíčem pro Android nebo certifikátem Apple. Podpisové soubory si zajišťuje vydavatel. Nákupy přes obchod, biometrii, výběr souborů a tisk je třeba vyzkoušet na cílové platformě nebo zařízení.

APK z GitHubu vyžaduje Android 7 nebo novější. Používá identifikátor `cz.aardvarkland.cashtally`, takže jde nainstalovat vedle dřívější aplikace. Pro sestavení s tímto identifikátorem nastavte `AARDVARKLAND_GITHUB_APK=1` před spuštěním `flutter build apk --release`.

### Ukládání dat

Částky se ukládají jako celá čísla v nejmenších jednotkách měny. Sestavy, historie i šifrované zálohy vznikají přímo na zařízení. Aplikace funguje bez serveru. Do veřejných hlášení nevkládejte skutečné exporty z pokladen, podpisy ani obchodní záznamy.

- [Hlášení bezpečnostních problémů](SECURITY.md)
- [Jak přispět](CONTRIBUTING.md)

### Licence

[MIT](LICENSE)
