import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

/// 전체화면 이미지 뷰어
///
/// PageView로 여러 이미지를 스와이프하며 볼 수 있고,
/// InteractiveViewer로 확대/축소가 가능합니다.
/// Hero 애니메이션을 지원합니다.
class FullscreenImageViewer extends StatefulWidget {
  /// 이미지 경로 목록
  final List<String> imagePaths;

  /// 처음 표시할 이미지 인덱스
  final int initialIndex;

  /// Hero 태그 접두사 (Hero 애니메이션용)
  final String? heroTagPrefix;

  const FullscreenImageViewer({
    super.key,
    required this.imagePaths,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  /// 전체화면 이미지 뷰어를 모달로 표시합니다.
  static Future<void> show(
    BuildContext context, {
    required List<String> imagePaths,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageViewer(
            imagePaths: imagePaths,
            initialIndex: initialIndex,
            heroTagPrefix: heroTagPrefix,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // 상태바 숨김
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 상태바 복원
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // 아래로 스와이프하면 닫기
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            context.pop();
          }
        },
        child: Stack(
          children: [
            // 이미지 페이지 뷰
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imagePaths.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final imagePath = widget.imagePaths[index];
                final heroTag = widget.heroTagPrefix != null
                    ? '${widget.heroTagPrefix}_$index'
                    : null;

                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: heroTag != null
                        ? Hero(
                            tag: heroTag,
                            child: _buildImage(imagePath),
                          )
                        : _buildImage(imagePath),
                  ),
                );
              },
            ),

            // 닫기 버튼
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // 페이지 인디케이터 (2개 이상일 때만 표시)
            if (widget.imagePaths.length > 1)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.imagePaths.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

            // 페이지 번호 표시 (2개 이상일 때만)
            if (widget.imagePaths.length > 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imagePaths.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 200,
          height: 200,
          color: Colors.grey[900],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                '이미지를 불러올 수 없습니다',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.statsPrimary
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
