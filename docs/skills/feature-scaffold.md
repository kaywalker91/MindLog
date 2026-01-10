# feature-scaffold

Clean Architecture 기능 스캐폴딩 (`/scaffold [feature_name]`)

## 프로젝트 구조
```
lib/
├── domain/          # 순수 Dart (entities, repositories 인터페이스, usecases)
├── data/            # Repository 구현체, DataSources, DTOs
├── presentation/    # Riverpod Providers, Screens, Widgets
└── core/            # 공통 (errors, config, constants)
```

## 생성 파일

| 파일 | 경로 |
|------|------|
| Entity | `lib/domain/entities/{feature}.dart` |
| Repository Interface | `lib/domain/repositories/{feature}_repository.dart` |
| UseCase | `lib/domain/usecases/{action}_{feature}_usecase.dart` |
| Repository Impl | `lib/data/repositories/{feature}_repository_impl.dart` |
| Test | `test/domain/usecases/{action}_{feature}_usecase_test.dart` |

## 템플릿

### Entity
```dart
@JsonSerializable()
class {Feature} {
  final String id;
  const {Feature}({required this.id});
  {Feature} copyWith({String? id}) => {Feature}(id: id ?? this.id);
  factory {Feature}.fromJson(Map<String, dynamic> json) => _${Feature}FromJson(json);
  Map<String, dynamic> toJson() => _${Feature}ToJson(this);
}
```

### Repository Interface
```dart
abstract class {Feature}Repository {
  Future<{Feature}> create{Feature}(/* params */);
  Future<{Feature}?> get{Feature}ById(String id);
  Future<List<{Feature}>> getAll{Feature}s();
  Future<void> delete{Feature}(String id);
}
```

### UseCase
```dart
class {Action}{Feature}UseCase {
  final {Feature}Repository _repository;
  {Action}{Feature}UseCase(this._repository);

  Future<{Feature}> execute(/* params */) async {
    try {
      return await _repository.someMethod(/* args */);
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnknownFailure(message: e.toString());
    }
  }
}
```

### Provider 등록 (수동)
```dart
final {feature}RepositoryProvider = Provider<{Feature}Repository>((ref) {
  return {Feature}RepositoryImpl(localDataSource: ref.watch({feature}LocalDataSourceProvider));
});
```

## 레이어 의존성 규칙
- `presentation → domain` (O)
- `data → domain` (O)
- `domain → data/presentation` (X - 금지)

## 후속 작업
1. `providers.dart`에 Provider 등록
2. `flutter pub run build_runner build`
3. DataSource 구현 (필요시)
