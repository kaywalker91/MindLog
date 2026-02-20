# MindLog - AI-Powered Emotional Care Diary

> Made with ❤️ for your mental health

## 📱 Project Overview

**MindLog** is a mental healthcare application that leverages AI technology to analyze users' daily emotions and provide personalized insights. Record your feelings gently every day and manage your mental health with warm AI-powered feedback.

### 🎯 Core Values

- **Emotion Visualization**: Record daily emotions and discover patterns
- **AI-Based Analysis**: Sophisticated emotion analysis and insights using LLM
- **Personalized Care**: Choose AI character matching your personality for tailored feedback
- **Privacy First**: Secure personal data management with local SQLite storage

---

## ✨ Key Features

### 1️⃣ Emotional Diary Writing

- **Free-form Text Input**: Record today's emotions and thoughts up to 5,000 characters
- **Photo Attachment**: Visual recording with up to 5 photos
- **AI Analysis**: Real-time emotion analysis using Groq API (LLaMA 3.3 70B)
- **Auto Hashtag Generation**: AI analyzes diary content to extract key keywords

### 2️⃣ Emotional Statistics & Insights

#### 📅 Emotion Calendar
- View monthly emotion records at a glance
- Track average emotion score and consecutive writing days
- "Emotion Garden" - Visualize emotional growth stages with plant images

#### 📊 Emotion Trend Chart
- Time-series emotion change graph using fl_chart library
- Filter support for last 7/30 days or all-time period
- Emotion pattern summary

#### 🔑 Keyword Analysis
- Frequency analysis of AI-extracted emotion keywords
- Representative emotion and most frequent emotion rankings
- Keyword appearance ratio visualization

### 3️⃣ Personalized AI Characters

Choose from 3 AI characters matching your personality:

- **Oni** (Warm Counselor): Gentle and warm empathy-focused
- **Koi** (Realistic Coach): Clear and action-oriented advice
- **Smile** (Cheerful Friend): Bright and pleasant comfort

### 4️⃣ Smart Notification System

- **Diary Reminder**: Daily diary writing notification at set time
- **Mindcare Alert**: AI-recommended warm message push
- **Personalized Messages**: Customized notification phrases based on user name

---

## 🏗️ Tech Stack

### Frontend
- **Flutter** 3.38.9 / **Dart** 3.10.8
- **fvm** (Flutter Version Management)
- **Riverpod** 2.6.1 - State Management
- **go_router** 17.0.1 - Declarative Routing
- **fl_chart** 0.68.0 - Data Visualization

### Backend & AI
- **Groq API** - LLaMA 3.3 70B Versatile Model
  - Emotion analysis, keyword extraction, AI character responses
- **Firebase**
  - Analytics 3.8.0+ - User behavior analysis
  - Crashlytics - Stability monitoring
  - FCM (Firebase Cloud Messaging) - Push notifications

### Database & Storage
- **SQLite** (sqflite 2.3.3) - Local Database
  - Store emotion diary, analysis results, user settings
  - Offline-first architecture

---

## 🎨 Architecture & Design

### Clean Architecture

```
lib/
├── core/           # Common: Error, Config, Services, Theme, Utils
├── domain/         # Business Logic: Entity, Repository, UseCase
├── data/           # Data Layer: Repository Implementation, DataSource, DTO
├── presentation/   # UI Layer: Provider, Screen, Widget
└── main.dart
```

### Core Design Patterns

#### 1. Clean Architecture
- **Layer Separation**: Domain (Pure Business) ↔ Data (Implementation) ↔ Presentation (UI)
- **Dependency Inversion**: Domain doesn't depend on Data/Presentation
- **Testability**: Independent unit testing per layer

#### 2. Riverpod State Management
```dart
// Execute business logic through UseCase
final diaryAnalysisProvider = AsyncNotifierProvider<DiaryAnalysisNotifier, DiaryAnalysis?>(
  DiaryAnalysisNotifier.new,
);

// Declarative UI rendering
ref.watch(diaryAnalysisProvider).when(
  data: (analysis) => AnalysisResultCard(analysis),
  loading: () => LoadingIndicator(),
  error: (error, _) => ErrorView(error),
);
```

#### 3. Repository Pattern
```dart
// Domain Layer - Interface
abstract class DiaryRepository {
  Future<Either<Failure, List<Diary>>> getAllDiaries();
  Future<Either<Failure, Diary>> saveDiary(Diary diary);
}

// Data Layer - Implementation
class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Diary>> saveDiary(Diary diary) async {
    try {
      final diaryDto = DiaryDto.fromEntity(diary);
      final result = await localDataSource.insertDiary(diaryDto);
      return Right(result.toEntity());
    } on DatabaseException {
      return Left(CacheFailure());
    }
  }
}
```

#### 4. Failure-based Error Handling
```dart
sealed class Failure {
  const Failure();
}

class NetworkFailure extends Failure {}
class ApiFailure extends Failure { final String message; }
class CacheFailure extends Failure {}
class SafetyBlockedFailure extends Failure {} // Block on crisis detection
```

---

## 🔐 Security & Privacy

### Data Protection
- **Local-first Storage**: Sensitive emotion data stored only in SQLite
- **API Key Security**: Environment variable injection via `--dart-define`
- **Privacy Policy**: GDPR/CCPA compliant design

### Crisis Detection System
```dart
// Returns SafetyBlockedFailure when AI detects danger signals
class SafetyBlockedFailure extends Failure {
  final String reason;
  const SafetyBlockedFailure(this.reason);
}

// NEVER modify/remove - Critical logic for emergency detection
```

---

## 📊 Performance Optimization

### 1. Rendering Optimization
- **Provider .select()**: Prevent unnecessary rebuilds by subscribing only to needed state
- **const Widgets**: Prevent recreation with const keyword for immutable widgets
- **ListView.builder**: Efficiently render large data sets

### 2. Memory Management
- **Image Caching**: Optimize memory usage with `cacheWidth` setting
- **RegExp Caching**: Declare frequently used RegExp as static final

### 3. API Call Optimization
- **HTTP Timeout**: Handle network delays with 30-second timeout
- **Error Handling**: Retry strategy with Exponential Backoff pattern

---

## 🧪 Testing Strategy

### TDD (Test-Driven Development)

| Layer | TDD Required | Coverage Goal |
|-------|--------------|---------------|
| **Domain** (UseCase, Entity) | **Mandatory** | ≥ 80% |
| **Data** (Repository, DataSource) | **Mandatory** | ≥ 80% |
| **Presentation** (Provider, Widget) | Recommended | ≥ 70% |

### Test Types
```bash
# Unit Tests (Domain + Data)
flutter test test/domain/ test/data/

# Widget Tests (Presentation)
flutter test test/presentation/widgets/

# Integration Tests
flutter test integration_test/
```

### Quality Gates
1. ✅ Syntax validation
2. ✅ Type checking (`flutter analyze`)
3. ✅ Lint/quality analysis (`flutter_lints`)
4. ✅ Security scan
5. ✅ Test coverage (unit ≥ 80%, widget ≥ 70%)
6. ✅ Performance check
7. ✅ Documentation validation
8. ✅ Integration testing

---

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

#### CI Pipeline (`.github/workflows/ci.yml`)
```yaml
trigger: PR to main/develop
steps:
  1. flutter analyze (Static analysis)
  2. flutter test (All tests)
  3. flutter build appbundle --debug (Build verification)
```

#### CD Pipeline (`.github/workflows/cd.yml`)
```yaml
trigger: push to main
steps:
  1. flutter test (Tests)
  2. flutter build appbundle --release (Release build)
  3. Deploy to Google Play Store Internal Track
```

### Environment Variable Management
```bash
# Production build
flutter build appbundle --release \
  --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
  --dart-define=ENVIRONMENT=production
```

---

## 📈 Key Achievements

### Technical Achievements
- ✅ **1,384 tests** all passing (unit/widget/integration)
- ✅ **Clean Architecture** based scalable structure
- ✅ **AI Integration**: Utilizing Groq LLaMA 3.3 70B model
- ✅ **Performance Optimization**: HTTP timeout, image caching, Provider optimization

### User Experience
- 🎨 **Material 3 Design System** applied
- 🌙 **Dark Mode** fully supported
- 📱 **Responsive Layout** (supports various screen sizes)
- ♿ **Accessibility** considered (Semantics widgets, screen reader support)

### Code Quality
- 📐 **flutter_lints** strict lint rules compliance
- 📝 **Conventional Commits** convention
- 🔍 **Code Review** mandatory (Security/Performance/Architecture 3-stage)

---

## 🛠️ Development Setup

### Prerequisites
```bash
# Install Flutter Version Manager
brew tap leoafarias/fvm
brew install fvm

# Install project Flutter version
fvm install 3.38.9
fvm use 3.38.9
```

### Local Execution
```bash
# Install dependencies
flutter pub get

# Run app (API Key required)
GROQ_API_KEY=your_api_key ./scripts/run.sh build-appbundle

# Quality check
./scripts/run.sh quality  # lint + format + test
```

---

---

## 🏆 Core Competencies Summary

### 1. Clean Architecture Design
- Domain-Data-Presentation layer separation
- SOLID principles compliance
- Testable structure design

### 2. State Management (Riverpod)
- Provider centralization and invalidation chain design
- Optimistic update vs Invalidation pattern utilization
- AsyncNotifier-based async state management

### 3. AI/LLM Integration
- Emotion analysis pipeline using Groq API
- Prompt engineering (Korean optimization)
- Error handling and fallback strategy

### 4. Database Design
- SQLite schema design and migration
- Transaction-based data integrity guarantee
- Recovery defense logic implementation

### 5. DevOps & Automation
- GitHub Actions CI/CD pipeline
- Play Store automated deployment
- Version management and changelog automation

---

## 📄 License

Copyright © 2024 Kay Walker. All rights reserved.

---

## 📧 Contact

- **GitHub**: [@kaywalker](https://github.com/kaywalker)
- **Email**: your.email@example.com

---

**MindLog** - Record today's emotions gently ❤️
