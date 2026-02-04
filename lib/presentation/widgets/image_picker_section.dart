import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 이미지 선택 섹션 위젯
///
/// 일기 작성 화면에서 이미지를 선택/촬영하고 미리보기를 제공합니다.
class ImagePickerSection extends StatelessWidget {
  /// 선택된 이미지 경로 목록
  final List<String> imagePaths;

  /// 이미지 추가 콜백
  final void Function(String path) onImageAdded;

  /// 이미지 삭제 콜백
  final void Function(int index) onImageRemoved;

  /// 분석 중 여부 (비활성화 상태)
  final bool isLoading;

  const ImagePickerSection({
    super.key,
    required this.imagePaths,
    required this.onImageAdded,
    required this.onImageRemoved,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canAddMore = imagePaths.length < AppConstants.maxImagesPerDiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              '사진 첨부',
              style: AppTextStyles.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${imagePaths.length}/${AppConstants.maxImagesPerDiary}',
              style: AppTextStyles.label.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 이미지 그리드 + 추가 버튼
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 선택된 이미지들
            ...List.generate(
              imagePaths.length,
              (index) => _ImagePreviewTile(
                imagePath: imagePaths[index],
                onRemove: isLoading ? null : () => onImageRemoved(index),
              ),
            ),

            // 추가 버튼 (최대 개수 미만일 때만 표시)
            if (canAddMore && !isLoading)
              _AddImageButton(
                onGalleryTap: () => _pickFromGallery(context),
                onCameraTap: () => _pickFromCamera(context),
              ),
          ],
        ),

        // 안내 텍스트
        if (imagePaths.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '사진을 첨부하면 AI가 이미지도 함께 분석해요',
            style: AppTextStyles.label.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final remainingSlots = AppConstants.maxImagesPerDiary - imagePaths.length;

    if (remainingSlots <= 0) return;

    try {
      if (remainingSlots == 1) {
        // 1개만 선택 가능할 때는 단일 선택
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (image != null) {
          onImageAdded(image.path);
        }
      } else {
        // 여러 개 선택 가능할 때는 다중 선택
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 90,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        // 남은 슬롯만큼만 추가
        for (int i = 0; i < images.length && i < remainingSlots; i++) {
          onImageAdded(images[i].path);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<void> _pickFromCamera(BuildContext context) async {
    final picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        onImageAdded(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('카메라를 사용할 수 없습니다.')));
      }
    }
  }
}

/// 이미지 미리보기 타일
class _ImagePreviewTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onRemove;

  const _ImagePreviewTile({required this.imagePath, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // 이미지
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),

        // 삭제 버튼
        if (onRemove != null)
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// 이미지 추가 버튼
class _AddImageButton extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  const _AddImageButton({
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 28,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              '추가',
              style: AppTextStyles.label.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  onGalleryTap();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: colorScheme.primary,
                ),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  onCameraTap();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
