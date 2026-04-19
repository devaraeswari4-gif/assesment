# QR Scanner & Product Verification

iOS take-home submission: scan QR codes with **AVFoundation**, verify products via **Open Food Facts**, show results with **Genuine / Unverified** styling, and keep a **searchable offline history**.

## Requirements coverage

| Requirement | Implementation |
|-------------|----------------|
| QR scanning (AVFoundation), live preview, overlay | `ScannerViewController` + `QRScanFrameOverlayView` |
| Permission denied UX | Alert + `NSCameraUsageDescription` |
| REST API + product fields | Open Food Facts → name, category, verification flag |
| Visual verified / unverified | Green / red on product and history |
| API errors | Alert with network-oriented copy; loading spinner while fetching |
| Offline history | `UserDefaults` + JSON (`StorageManager`) |
| History: name, time, status, delete | `HistoryViewController`; delete by stable `UUID` |
| Search by name | `UISearchController` |
| Filter by status (optional) | Segmented control: All / Genuine / Unverified |

## Architecture

- **UIKit** app with a **navigation stack**: `HomeViewController` → scanner or history → product detail.
- **Light MVVM**: `ProductViewModel` loads async data and holds `Product`; view controllers own UI.
- **Services**: `NetworkManager` (async/await, `URLSession`).
- **Persistence**: `StorageManager` wraps `UserDefaults` and `Codable` for `ScanRecord`.

**Why UserDefaults (not Core Data / SwiftData)?**  
The assignment allows any local store; the dataset is small (a list of scans), no relationships or heavy queries, and JSON encoding keeps the code small within the time box. For production scale or sync, migration to SwiftData/Core Data would be reasonable.

## Libraries

None beyond Apple frameworks. No third-party networking or UI dependencies.

## API assumption

[Open Food Facts](https://world.openfoodfacts.org/) expects a **barcode** (EAN/UPC) as the path segment. Many QR codes encode URLs or text that are not barcodes; those lookups may return unknown or unverified products. The app treats a missing `product` in the JSON as unverified and still shows a placeholder name.

## Simulator

On Simulator, camera hardware may be unavailable: use **Simulate** to enter a barcode manually (e.g. from Open Food Facts product pages).

## Build & run

1. Open `QRScannerApp/QRScannerApp.xcodeproj` in Xcode.
2. Select an iPhone simulator or device.
3. Run (**⌘R**). No extra setup steps.

## Known limitations

- Verification is **not** cryptographic proof of authenticity; it only reflects whether Open Food Facts returned a product for the scanned string.
- No pagination or large-history performance tuning.
- `rectOfInterest` for the metadata output is not tuned to the overlay (visual guide only).
- Unit tests are minimal (template only).

## What I would improve with more time

- Map common QR payloads (e.g. strip URL to extract a code) before calling the API.
- Persist `ScanRecord` with SwiftData and optional iCloud sync.
- Richer error types (timeout, HTTP 4xx/5xx, decoding) and retry.
- Snapshot / unit tests for storage and view models.
- VoiceOver polish pass on dynamic scanner and result screens.
