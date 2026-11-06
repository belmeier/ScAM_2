# ScAM 2 🧾📸

**ScAM 2** is an iOS application built with SwiftUI designed to automatically detect, straighten, and crop receipt photos so they can be cleanly forwarded for bill splitting, expense tracking, and payment sharing.

Originally built from scratch with assistance from Google Gemini, the primary goal of this project is educational: serving as a practical blueprint for students and iOS developers to learn how Apple's **Vision Framework** transforms raw photos into useful real-world tools.

---

## 🎯 Educational Goal

Many machine vision tutorials focus heavily on lower-level computer vision theory or abstract image encoding. **ScAM 2** takes a product-first approach:
- Showing students how readily available Apple frameworks solve real daily friction (e.g., poorly angled, crumpled receipt photos in group chats).
-  Using the updated **Modern Swift-Native Vision APIs** introduced in iOS 18+.

---

## ✨ Features & Recent Updates

### 🔍 Vision & Image Processing
* **Receipt Edge & Rectangle Detection**: Detects receipt boundaries using Vision quadrilateral analysis.
* **Modern Swift API Migration**: Refactored the core image processing pipeline from traditional completion-handler-based Vision calls to the modern, Swift-native, concurrency-driven Vision API (`perform(on:)` with `async/await`).
* **Photo Library Export**: Dedicated image-saving workflow (`ImageSaver`) allowing one-tap export of processed receipts back to the device's photo roll.

### 🎨 UI & Experience
* **Custom App Identity**: Branded application identity, tailored color palette, and adaptive UI components.
* **Splash & Loading Indicators**: Visual progress states while Vision processes receipt geometries in the background.

### 🛠 Tooling & Workflow
* **Automated Versioning**: Integrated Xcode build phase script that automatically increments the project build number with each compile.
* **Marketing Version Updates**: Maintained release versioning tracking each milestone of the project's evolution.

---

## 🏗 Architecture & Tech Stack

* **Platform**: iOS 18.0+
* **Framework**: SwiftUI (Declarative UI)
* **Vision & Concurrency**: 
  * Apple Vision Framework (`DetectRectanglesRequest`, `VNRectangleObservation`)
  * Swift Structured Concurrency (`async/await`, `@MainActor`)
* **Storage & Export**: Photos / UIKit integration for camera roll saving
* **Environment**: Xcode 16+, Swift 6

---

## 🔄 Vision Workflow Pipeline

```text
[ Raw Photo / Camera Input ]
             │
             ▼
[ Vision Request: DetectRectanglesRequest ]
             │
             ▼
[ Geometry Extraction: Bounding Box & Corners ]
             │
             ▼
[ Auto-Fix / Straighten & Crop ]
             │
             ▼
[ Export / Save via ImageSaver ]
```

---

## 🚀 Getting Started

1. Clone this repository:
   ```bash
   git clone [https://github.com/belmeier/ScAM_2.git](https://github.com/belmeier/ScAM_2.git)
   ```
2. Open `ScAM_2.xcodeproj` in **Xcode 16+**.
3. Select your target device or simulator (iOS 18+ recommended for modern Vision API features).
4. Press **⌘ + R** to build and run.

---

## 👨‍💻 Author

Created and maintained by **Belmeier Raymond** ([belmeier@gmail.com](mailto:belmeier@gmail.com)).
