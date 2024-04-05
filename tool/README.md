# Carbon Icons Generator

The `generate.dart` script will convert downloaded SVGs into a TTF font, then generated a Dart file that maps the icon names to the Unicode code points in the generated font.

### Prerequisites

- Dart
- `fantasticon` (install using `npm install -g fantasticon`)
- `svg-cleaner` (install using `npm install -g svg-cleaner`)

#### Generating

- Download the latest icons from https://iconer.app/carbon/
- Extract the zip file in the [`svg/`](./svg/) directory. There should be two directories inside the `svg` directory after extracting: `line/` and `solid/`.
- Run the generator: `dart generate.dart`

That's it!

The newly generated TTF font can be found in [`assets/CarbonFonts.ttf`](../assets/CarbonFonts.ttf) and the Dart file can be found in [`lib/src/fonts/carbon_fonts.dart`](../lib/src/fonts/carbon_fonts.dart).
