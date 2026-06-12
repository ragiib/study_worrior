# ⚔️ Study Warrior

> A premium, comprehensive study productivity application built with Flutter to help students conquer their academic goals.

**Study Warrior** is an all-in-one productivity suite designed to keep you focused, organized, and motivated. It combines task management, time tracking, habit building, and AI-powered study assistance into one beautiful, offline-first application.

---

## ✨ Features

### 📊 Dashboard & Analytics
- **Dynamic Greeting:** Welcomes you based on the time of day.
- **Study Analytics:** Beautiful interactive charts showing your study hours over the week.
- **Quick Actions:** One-tap access to your most-used tools directly from the home screen.

### 📝 AI Notes Generator (New!)
- **OCR Text Extraction:** Take a picture of your textbook or upload from your gallery, and the app instantly extracts the text using Google ML Kit.
- **AI Processing:** Convert raw text into highly structured study materials:
  - Short Summaries
  - Detailed Notes & Bullet Points
  - Formulas & Important Definitions
  - Exam-Oriented Prep & MCQs
- **Note Management:** Edit generated notes, export them beautifully as PDF files, or share them with classmates.
- **Persistent Storage:** All notes are saved locally and are fully searchable.

### ✅ Task Manager
- **Smart Organization:** Add, edit, and organize your tasks.
- **Categorization:** Categorize tasks by subject or type for better visibility.
- **Local Persistence:** Your tasks are saved securely on your device using Hive.

### ⏱️ Pomodoro Timer
- **Focus Sessions:** Built-in Pomodoro technique timer to maximize your focus.
- **Customizable Intervals:** Set your own work and break durations.
- **Notifications:** Receive alerts when it's time to take a break or get back to work.

### 📈 Habit Tracker
- **Build Consistency:** Track daily habits essential for student life (e.g., "Read 20 pages", "Drink Water").
- **Streak Tracking:** Keep the chain alive with visual streak counters.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** `provider`
- **Local Database:** `hive` & `hive_flutter` (NoSQL, lightning fast)
- **Charts:** `fl_chart` for beautiful analytics
- **Machine Learning:** `google_mlkit_text_recognition` for on-device OCR
- **PDF Generation:** `pdf` & `printing`
- **Markdown Rendering:** `flutter_markdown`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK installed on your machine ([Installation Guide](https://docs.flutter.dev/get-started/install))
- A connected device or emulator (Android/iOS) or a web browser for web testing.

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/study_warrior.git
   cd study_warrior
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```
   *(Note: Since this app uses native packages like ML Kit, a clean build on a physical device or emulator is highly recommended over hot-reloading on the web).*

---

## 🎨 UI Showcase
*(You can add your app screenshots here!)*

| Dashboard | AI Notes Generator | Notes Viewer |
|:---:|:---:|:---:|
| <img src="screenshots/dashboard.png" width="200"/> | <img src="screenshots/ai_generator.png" width="200"/> | <img src="screenshots/ai_viewer.png" width="200"/> |

---

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/yourusername/study_warrior/issues).

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
