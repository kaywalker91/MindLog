import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/animation_settings.dart';
import 'fullscreen_image_viewer.dart';

/// 일기 상세 화면에서 첨부 이미지를 그리드로 표시하는 갤러리 위젯
///
/// 2열 그리드로 이미지를 표시하고, 탭 시 전체화면 뷰어를 엽니다.
class DiaryImageGallery extends StatelessWidget {
  /// 이미지 경로 목록
  final List<String> imagePaths;

  /// 갤러리 고유 식별자 (Hero 애니메이션용)
  final String? galleryId;

  const DiaryImageGallery({
    super.key,
    required this.imagePaths,
    this.galleryId,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final shouldAnimate = AnimationSettings.shouldAnimate(context);
    final heroPrefix = galleryId ?? 'diary_gallery';

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
              '첨부 사진',
              style: AppTextStyles.label.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              '${imagePaths.length}장',
              style: AppTextStyles.label.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2열 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            final imagePath = imagePaths[index];
            final heroTag = '${heroPrefix}_$index';

            Widget tile = _ImageTile(
              imagePath: imagePath,
              heroTag: heroTag,
              onTap: () {
                FullscreenImageViewer.show(
                  context,
                  imagePaths: imagePaths,
                  initialIndex: index,
                  heroTagPrefix: heroPrefix,
                );
              },
            );

            // 스태거 애니메이션 적용
            if (shouldAnimate) {
              final delay = (index * 80).ms;
              tile = tile
                  .animate()
                  .fadeIn(delay: delay, duration: 300.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    delay: delay,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  );
            }

            return tile;
          },
        ),
      ],
    );
  }
}

/// 개별 이미지 타일
class _ImageTile extends StatefulWidget {
  final String imagePath;
  final String heroTag;
  final VoidCallback onTap;

  const _ImageTile({
    required this.imagePath,
    required this.heroTag,
    required this.onTap,
  });

  @override
  State<_ImageTile> createState() => _ImageTileState();
}

class _ImageTileState extends State<_ImageTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Hero(
          tag: widget.heroTag,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '이미지 오류',
                        style: AppTextStyles.label.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
