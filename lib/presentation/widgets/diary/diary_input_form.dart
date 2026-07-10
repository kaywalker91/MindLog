import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../image_picker_section.dart';

/// Diary text + image + date chip form extracted from [DiaryScreen].
///
/// Owns no analysis/overlay state — parent keeps network overlay + analysis flow.
class DiaryInputForm extends StatelessWidget {
  const DiaryInputForm({
    super.key,
    required this.formKey,
    required this.textController,
    required this.dateChipLabel,
    required this.isTodaySelected,
    required this.selectedImagePaths,
    required this.onPickDate,
    required this.onImageAdded,
    required this.onImageRemoved,
    required this.onSubmit,
    required this.onTextChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController textController;
  final String dateChipLabel;
  final bool isTodaySelected;
  final List<String> selectedImagePaths;
  final VoidCallback onPickDate;
  final ValueChanged<String> onImageAdded;
  final ValueChanged<int> onImageRemoved;
  final VoidCallback onSubmit;
  final VoidCallback onTextChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '오늘 하루는 어떠셨나요?',
            style: AppTextStyles.headline.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '마음 속 이야기를 자유롭게 적어보세요.',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: ActionChip(
              avatar: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.primary, // design-ok: 아이콘 브랜드 액센트
              ),
              label: Text(
                dateChipLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isTodaySelected
                      ? colorScheme.onSurfaceVariant
                      : AppColors.primaryDark,
                  fontWeight: isTodaySelected
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
              side: isTodaySelected
                  ? null
                  : const BorderSide(
                      color: AppColors.primary, // design-ok: 강조선 브랜드 액센트
                    ),
              onPressed: onPickDate,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: textController,
            maxLines: 8,
            maxLength: AppConstants.diaryMaxLength,
            decoration: const InputDecoration(
              hintText: AppStrings.diaryHint,
              alignLabelWithHint: true,
            ),
            validator: Validators.validateDiaryContent,
            onChanged: (_) => onTextChanged(),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) {
                  final len = currentLength;
                  final Color color;
                  if (len >= AppConstants.diaryMaxLength) {
                    color = AppColors.error;
                  } else if (len >= 4500) {
                    color = AppColors.warning;
                  } else {
                    color = Theme.of(context).colorScheme.onSurfaceVariant;
                  }
                  final String formatted = len >= 1000
                      ? '${len ~/ 1000},${(len % 1000).toString().padLeft(3, '0')}'
                      : '$len';
                  return Text(
                    '$formatted/5,000',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: color),
                  );
                },
          ),
          const SizedBox(height: 16),
          ImagePickerSection(
            imagePaths: selectedImagePaths,
            onImageAdded: onImageAdded,
            onImageRemoved: onImageRemoved,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed:
                textController.text.trim().length >= AppConstants.diaryMinLength
                ? onSubmit
                : null,
            child: Text(
              selectedImagePaths.isNotEmpty
                  ? '${AppStrings.submitButton} (사진 ${selectedImagePaths.length}장 포함)'
                  : AppStrings.submitButton,
            ),
          ),
        ],
      ),
    );
  }
}
