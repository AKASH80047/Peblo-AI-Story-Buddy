<<<<<<< HEAD
# 🤖 Peblo AI Story Buddy

A **production-ready, kid-friendly Flutter application** built for the Peblo Flutter Developer Intern Challenge. The app narrates a short story via text-to-speech and automatically reveals a dynamic quiz when narration completes.

---

## ✨ Features

- 🎙️ **TTS Narration** — Story read aloud using `flutter_tts`
- 🧠 **Dynamic Quiz** — Data-driven options (3/4/5) via `ListView.builder`
- 🎉 **Confetti Celebration** — On correct answer via `confetti`
- 📳 **Haptic Feedback** — Wrong answer vibration via `vibration`
- 🌊 **Smooth Animations** — Float, reveal, shake via `flutter_animate`
- 🎨 **Material 3 Design** — Nunito font, brand colour system
- 🏗️ **Clean Architecture** — Layered: core → data → domain → presentation
- 🧪 **Tests** — Unit + widget tests included

---

## 🏗️ Framework Choice: Flutter + Riverpod

### Why Flutter?
Flutter compiles to native ARM code via Dart's AOT compiler, achieving **60 FPS** on mid-range Android devices (3GB RAM). A single codebase targets Android, iOS, and Web without platform-specific rewrites.

### Why Riverpod?
Riverpod was chosen over `setState`, `Provider`, or `Bloc` for several reasons:

| Feature | Riverpod |
|---|---|
| Compile-time safety | ✅ Providers are type-safe |
| Testability | ✅ Override any provider in tests |
| No `BuildContext` leaks | ✅ Providers live outside widget tree |
| Selective rebuilds | ✅ `select()` minimises unnecessary repaints |
| Lifecycle management | ✅ `ref.onDispose()` prevents resource leaks |

---

## 🔊 Audio-to-Quiz Transition

The transition from narration to quiz uses a **stream-based callback chain**:

```
User taps button
  │
  ▼
AudioNotifier.readStory(text)
  │
  ▼
TtsService.speak(text)
  │  ├── emits: loading
  │  ├── emits: playing
  │  └── FlutterTts.setCompletionHandler()
  │            │
  │            ▼
  │         emits: completed  ◄── This is the key event
  │
  ▼
audioProvider listener (in HomeScreen.initState)
  │
  ▼
QuizNotifier.revealQuiz(correctAnswer)
  │
  ▼
QuizStatus.visible  →  QuizCardWidget fades in
```

**Why streams?** `flutter_tts` exposes callbacks, not Futures. By wrapping them in a `StreamController.broadcast()`, Riverpod providers can reactively listen without polling or manual state mutation.

---

## 🎯 Data-Driven Quiz

The quiz widget renders options **entirely from data** — no hardcoded buttons.

```dart
// QuizCardWidget — the ONLY place options are rendered
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: quiz.options.length,  // ← drives rendering
  itemBuilder: (context, index) {
    return OptionButtonWidget(
      label: quiz.options[index],
      index: index,
      state: _resolveOptionState(...),
      onTap: () => _onOptionTapped(index),
    );
  },
)
```

To change from 4 options to 3 or 5, **only the JSON changes**:

```json
// 3 options
{ "options": ["Red", "Blue", "Green"] }

// 5 options  
{ "options": ["Red", "Blue", "Green", "Yellow", "Purple"] }
```

No widget code changes are needed.

---

## 💾 Caching Strategy

### Current: In-Memory Cache

```dart
class QuizRepository {
  QuizModel? _cachedQuiz; // ← parsed once, reused forever

  ({QuizModel? quiz, AppError? error}) getQuiz() {
    if (_cachedQuiz != null) return (quiz: _cachedQuiz, error: null);
    // parse JSON → cache → return
  }
}
```

- **Latency**: O(1) on cache hit (no I/O, no parsing)
- **Memory**: ~200 bytes per QuizModel instance — negligible
- **Lifetime**: Lives for the app session; cleared on app restart

### Future Enhancement: Audio File Cache

```dart
// Planned: cache synthesised audio bytes to avoid re-synthesis
class AudioCache {
  final Map<String, Uint8List> _cache = {};
  
  Future<Uint8List?> getAudio(String text) async {
    if (_cache.containsKey(text)) return _cache[text];
    final bytes = await tts.synthesize(text);
    _cache[text] = bytes;
    return bytes;
  }
}
```

---

## ⚠️ Error Handling

All errors are typed via the sealed `AppError` hierarchy:

```dart
sealed class AppError { final String message; }
final class TtsInitError extends AppError { ... }
final class TtsSpeakError extends AppError { ... }
final class AudioInterruptedError extends AppError { ... }
final class JsonParseError extends AppError { ... }
final class EmptyQuizError extends AppError { ... }
final class UnknownError extends AppError { ... }
```

### Loading + Retry Flow

```
TTS Error
  │
  ├── Snackbar with "Retry" action (6 second timeout)
  │
  └── AppErrorWidget replaces button
        └── "Try Again" → calls retryStory()
              └── stop() → reset() → readStory()
```

---

## ⚡ Performance Profiling

### 60 FPS Strategy

| Technique | Applied Where |
|---|---|
| `const` widgets | All static widgets (StoryCard, SuccessWidget, decorations) |
| `RepaintBoundary` | BuddyWidget, StarsPainter, BuddyFloatAnimation |
| Riverpod `select()` | Each Consumer watches only its state slice |
| `ConsumerWidget` | BuddySection, AudioButton, QuizSection (not the whole screen) |
| `CustomPainter.shouldRepaint` | Returns `false` for static painters |
| `shrinkWrap` ListView | Quiz options don't trigger full layout reflows |
| `NeverScrollableScrollPhysics` | Prevents nested scroll conflicts |

### Frame Rendering Analysis

Run the following to profile on a real device:

```bash
flutter run --profile
# In DevTools → Performance tab → enable "Track widget builds"
# Target: all frames < 16.67ms (60 FPS)
```

For 3GB RAM Android devices, the primary concern is **GC pressure**. Avoided by:
- Using `const` constructors (objects created once at compile time)
- Caching parsed models in `QuizRepository`
- Not creating anonymous closures in `build()` methods

---

## 📱 Lightweight Optimization for Mid-Range Android

1. **No external image assets** — buddy is drawn with `CustomPainter`
2. **No heavy third-party UI libraries** — only dart-native drawing
3. **Minimal provider count** — 3 providers total (audio, quiz, story)
4. **No FutureProvider/StreamProvider** — synchronous quiz data avoids async overhead
5. **Portrait-only lock** — prevents orientation change redraws

---

## 🤖 AI Usage Disclosure

> This application's architecture, folder structure, and code patterns were **designed with AI assistance** (Google Gemini / Antigravity IDE) as a code generation and architecture consultation tool.
>
> **All generated code was reviewed, understood, and validated** by the developer prior to submission. The developer is responsible for every line of code in this repository and can explain the rationale behind each architectural decision.
>
> AI was used for: scaffold generation, boilerplate, documentation drafting.  
> AI was NOT used for: design decisions, algorithm selection, or blind copy-paste without review.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Dart SDK 3.5+
- Android device/emulator with TTS engine (Google TTS recommended)

### Installation

```bash
git clone <repo-url>
cd peblo_ai_story_buddy
flutter pub get
flutter run
```

### Run Tests

```bash
# Unit tests
flutter test test/unit_test/quiz_model_test.dart

# Widget tests
flutter test test/widget_test/quiz_widget_test.dart

# All tests
flutter test

# With coverage
flutter test --coverage
```

### Analyse Code

```bash
flutter analyze
```

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point
├── app/
│   ├── app.dart                       # Root widget + ProviderScope
│   └── theme.dart                     # Material 3 ThemeData
├── core/
│   ├── constants/app_constants.dart   # Colours, text, sizing tokens
│   ├── errors/app_error.dart          # Sealed error hierarchy
│   └── utils/json_parser.dart         # Safe JSON parsing
├── data/
│   ├── models/quiz_model.dart         # json_serializable model
│   └── repositories/quiz_repository.dart  # In-memory cache
├── domain/
│   └── entities/quiz_entity.dart      # Pure domain entity
├── services/
│   └── tts_service.dart              # flutter_tts wrapper + streams
└── presentation/
    ├── providers/
    │   ├── audio_provider.dart        # AudioStatus state
    │   ├── quiz_provider.dart         # QuizStatus + answer state
    │   └── story_provider.dart        # Quiz data provider
    ├── animations/
    │   ├── buddy_float_animation.dart # Continuous float
    │   ├── shake_animation.dart       # Wrong answer shake
    │   └── quiz_reveal_animation.dart # Fade + slide reveal
    ├── widgets/
    │   ├── buddy_widget.dart          # CustomPainter robot
    │   ├── story_card_widget.dart     # Story text card
    │   ├── read_story_button.dart     # Gradient TTS button
    │   ├── quiz_card_widget.dart      # Data-driven quiz
    │   ├── option_button_widget.dart  # Single answer option
    │   ├── success_widget.dart        # Correct answer card
    │   ├── app_error_widget.dart      # Reusable error display
    │   └── decorative_elements.dart   # Stars background
    └── screens/
        └── home_screen.dart           # Main screen
```

---

## 🎨 Design Tokens

| Token | Value |
|---|---|
| Primary | `#6C63FF` |
| Secondary | `#FFB84D` |
| Background | `#F8F9FF` |
| Success | `#4CAF50` |
| Error | `#FF5252` |
| Font | Nunito (Google Fonts) |
| Card radius | 24dp |
| Button radius | 20dp |
| Min touch target | 56dp |

---

*Built with ❤️ for the Peblo Flutter Intern Challenge*
=======
# Peblo-AI-Story-Buddy
AI Story Buddy &amp; Quiz Component built with Flutter for Peblo Intern Challenge.
>>>>>>> abe31a3e981e14ed73d7b29a134dc114d691016c
