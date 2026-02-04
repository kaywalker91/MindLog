import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/constants/app_constants.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/usecases/validate_diary_content_usecase.dart';

void main() {
  late ValidateDiaryContentUseCase useCase;

  setUp(() {
    useCase = ValidateDiaryContentUseCase();
  });

  group('ValidateDiaryContentUseCase', () {
    group('execute - 예외를 던지는 유효성 검사', () {
      test('빈 내용은 ValidationFailure를 던져야 한다', () {
        expect(() => useCase.execute(''), throwsA(isA<ValidationFailure>()));
      });

      test('공백만 있는 내용은 ValidationFailure를 던져야 한다', () {
        expect(() => useCase.execute('   '), throwsA(isA<ValidationFailure>()));
      });

      test('탭과 개행만 있는 내용은 ValidationFailure를 던져야 한다', () {
        expect(
          () => useCase.execute('\t\n  \n\t'),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('최소 길이 미만은 ValidationFailure를 던져야 한다', () {
        final shortContent = 'a' * (AppConstants.diaryMinLength - 1);
        expect(
          () => useCase.execute(shortContent),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('최대 길이 초과는 ValidationFailure를 던져야 한다', () {
        final longContent = 'a' * (AppConstants.diaryMaxLength + 1);
        expect(
          () => useCase.execute(longContent),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('유효한 내용은 DiaryValidationResult를 반환해야 한다', () {
        const validContent = '오늘 하루도 열심히 보냈다. 피곤하지만 뿌듯하다.';
        final result = useCase.execute(validContent);

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.sanitizedContent, validContent);
      });

      test('앞뒤 공백이 있는 유효한 내용은 trim된 결과를 반환해야 한다', () {
        const content = '  오늘 하루도 열심히 보냈다. 피곤하지만 뿌듯하다.  ';
        final result = useCase.execute(content);

        expect(result.isValid, true);
        expect(result.sanitizedContent, content.trim());
      });

      test('최소 길이 경계값은 유효해야 한다', () {
        final minContent = 'a' * AppConstants.diaryMinLength;
        final result = useCase.execute(minContent);

        expect(result.isValid, true);
        expect(result.sanitizedContent.length, AppConstants.diaryMinLength);
      });

      test('최대 길이 경계값은 유효해야 한다', () {
        final maxContent = 'a' * AppConstants.diaryMaxLength;
        final result = useCase.execute(maxContent);

        expect(result.isValid, true);
        expect(result.sanitizedContent.length, AppConstants.diaryMaxLength);
      });
    });

    group('validate - 예외 없이 결과 반환', () {
      test('빈 내용은 invalid 결과를 반환해야 한다', () {
        final result = useCase.validate('');

        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('입력'));
      });

      test('공백만 있는 내용은 invalid 결과를 반환해야 한다', () {
        final result = useCase.validate('   ');

        expect(result.isValid, false);
        expect(result.errorMessage, isNotNull);
      });

      test('최소 길이 미만은 invalid 결과를 반환해야 한다', () {
        final shortContent = 'a' * (AppConstants.diaryMinLength - 1);
        final result = useCase.validate(shortContent);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('최소'));
        expect(result.errorMessage, contains('${AppConstants.diaryMinLength}'));
      });

      test('최대 길이 초과는 invalid 결과를 반환해야 한다', () {
        final longContent = 'a' * (AppConstants.diaryMaxLength + 1);
        final result = useCase.validate(longContent);

        expect(result.isValid, false);
        expect(result.errorMessage, contains('최대'));
        expect(result.errorMessage, contains('${AppConstants.diaryMaxLength}'));
      });

      test('유효한 내용은 valid 결과를 반환해야 한다', () {
        const validContent = '오늘 하루도 열심히 보냈다. 피곤하지만 뿌듯하다.';
        final result = useCase.validate(validContent);

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.sanitizedContent, validContent);
      });

      test('앞뒤 공백이 있어도 trim 후 유효하면 valid 결과를 반환해야 한다', () {
        const content = '   오늘 하루도 열심히 보냈다. 피곤하지만 뿌듯하다.   ';
        final result = useCase.validate(content);

        expect(result.isValid, true);
        expect(result.sanitizedContent, content.trim());
      });
    });

    group('DiaryValidationResult', () {
      test('valid factory는 올바른 결과를 생성해야 한다', () {
        const content = '테스트 내용';
        final result = DiaryValidationResult.valid(content);

        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
        expect(result.sanitizedContent, content);
      });

      test('invalid factory는 올바른 결과를 생성해야 한다', () {
        const message = '에러 메시지';
        final result = DiaryValidationResult.invalid(message);

        expect(result.isValid, false);
        expect(result.errorMessage, message);
        expect(result.sanitizedContent, '');
      });
    });
  });
}
