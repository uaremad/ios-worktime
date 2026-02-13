# Measurement Module

A modern iOS 26 / macOS 26 input module for recording blood pressure measurements.

## Features

- ✅ Clean, accessible SwiftUI interface  
- ✅ Real-time input validation  
- ✅ Numeric keyboards for blood pressure and pulse values  
- ✅ Date picker for measurement time  
- ✅ Optional comment field  
- ✅ Full VoiceOver accessibility support  
- ✅ Platform-specific layouts (iOS & macOS)  
- ✅ Swift 6 concurrency with async/await  
- ✅ Core Data integration  

## Usage

### Basic Implementation

```swift
import SwiftUI

struct ContentView: View {
    @State private var viewModel = MeasurementViewModel(
        context: persistenceController.container.viewContext
    )
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            MeasurementInputView(viewModel: viewModel) { success in
                if success {
                    dismiss()
                }
            }
        }
    }
}
```

### ViewModel

The `MeasurementViewModel` manages all state and business logic:

- **Input validation**: Ensures values are within medical ranges  
- **Core Data persistence**: Automatic saving to BloodPressure entity  
- **Error handling**: User-friendly error messages  
- **Form reset**: Clears form after successful save  

```swift
let viewModel = MeasurementViewModel(context: managedObjectContext)

// Manual save
Task {
    let success = await viewModel.saveMeasurement()
    if success {
        print("Measurement saved successfully")
    }
}

// Reset form
viewModel.reset()
```

### Input Ranges

The following validation ranges are enforced:

| Field | Minimum | Maximum | Unit |
|-------|---------|---------|------|
| Systolic | 60 | 250 | mmHg |
| Diastolic | 40 | 200 | mmHg |
| Pulse | 30 | 220 | bpm |

## Localization

All strings are localized in `Measurement.xcstrings` with support for:

- 🇩🇪 German (de)
- 🇬🇧 English (en)
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇻🇦 Latin (la)
- 🇵🇹 Portuguese (pt)
- 🇷🇺 Russian (ru)

After modifying strings, run:

```bash
make swiftgen
```

## Accessibility

Every UI element includes proper accessibility labels, hints, and traits for VoiceOver support:

- Input fields announce their purpose and current values  
- Date picker provides formatted date/time strings  
- Error messages are conveyed with appropriate urgency  
- Button states (enabled/disabled) are communicated clearly  

## Architecture

### Files

- `MeasurementInputView.swift` - Main SwiftUI view  
- `MeasurementInputView+Platform.swift` - Platform-specific extensions  
- `MeasurementViewModel.swift` - State management and business logic  

### Dependencies

- CoreData (BloodPressure entity)  
- SwiftUI  
- Swift 6 Concurrency  

## Design

The view follows iOS 26 / macOS 26 design guidelines:

- Modern rounded corners and spacing  
- Semantic colors from app theme  
- Typography system with `.textStyle()` modifiers  
- Keyboard dismissal with toolbar button  
- ScrollView for smaller screens  

## Testing

Basic XCTest integration:

```swift
@MainActor
final class MeasurementViewModelTests: XCTestCase {
    func testSaveMeasurement() async throws {
        let context = // ... in-memory Core Data context
        let viewModel = MeasurementViewModel(context: context)
        
        viewModel.systolic = "120"
        viewModel.diastolic = "80"
        viewModel.pulse = "70"
        
        let success = await viewModel.saveMeasurement()
        XCTAssertTrue(success)
    }
}
```

## Requirements

- iOS 26.0+ / macOS 26.0+  
- Swift 6.0+  
- SwiftUI  
- Core Data  

---

**Created:** 2026-02-06  
**Last Updated:** 2026-02-06  
**Version:** 1.0.0
