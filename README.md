# Animated Icon Picker

A Flutter recreation of an animated app icon picker: a floating bottom sheet with a swipeable carousel of icons where the neighbours peek in rotated and blurred, a rolling `01 / 06` counter, and an activate button that really changes the home screen icon on iOS and Android.

## Structure

| Path | What it is |
| --- | --- |
| `docs/animation_analysis.md` | Frame-by-frame measurements of the reference video and the implementation spec |
| `lib/ui/picker_spec.dart` | Every measured constant (sizes, springs, colours, offsets) |
| `lib/ui/carousel_math.dart` | Pure mapping from page position to icon offset, scale, rotation and blur |
| `lib/ui/icon_carousel.dart` | Scroll-driven carousel and paging physics |
| `lib/ui/icon_picker_sheet.dart` | Sheet layout, name label, activation flow |
| `lib/ui/sheet_presenter.dart` | Spring presentation, drag to dismiss, rubber-band stretch |
| `lib/services/app_icon_service.dart` | Method channel client for switching icons |
| `tool/generate_icons.py` | Generates the artwork and every platform icon size |

## How icon switching works

- **iOS**: alternate app icons in the asset catalog, switched with `setAlternateIconName`. iOS shows its own confirmation alert; the sheet closes 0.3 s after it is dismissed.
- **Android**: one `<activity-alias>` per icon. Disabling the alias a task was launched from closes the app, so the switch is recorded and applied when the app leaves the foreground. Launchers may take a moment to refresh the icon.

## Running

```bash
flutter run
```

`flutter run` on Android always launches through the `MainActivityDefault` alias. After switching to another icon on a device, that alias is disabled and `flutter run` fails with "Activity class ... does not exist". Switch back to Default in the app, or uninstall the app first:

```bash
adb uninstall com.debojyoti.animated_icon_picker
```

## Regenerating icons

```bash
/usr/bin/python3 -I tool/generate_icons.py
```
