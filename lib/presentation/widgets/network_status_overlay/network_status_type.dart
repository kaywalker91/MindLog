/// 네트워크 상태 타입
enum NetworkStatusType {
  loading,
  networkError,
  apiError,
  retrySuccess,
}

/// NetworkStatusType 확장 메서드
extension NetworkStatusTypeExtension on NetworkStatusType {
  /// 상태 제목
  String get title {
    switch (this) {
      case NetworkStatusType.networkError:
        return '네트워크 연결 오류';
      case NetworkStatusType.apiError:
        return '응답 처리 오류';
      case NetworkStatusType.retrySuccess:
        return '성공적으로 완료!';
      case NetworkStatusType.loading:
        return '처리 중';
    }
  }

  /// 기본 메시지
  String get defaultMessage {
    switch (this) {
      case NetworkStatusType.networkError:
        return '인터넷 연결을 확인하고 다시 시도해주세요.\n자동으로 재시도 합니다...';
      case NetworkStatusType.apiError:
        return '서버 응답을 처리하는 데 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      case NetworkStatusType.retrySuccess:
        return '작업이 성공적으로 완료되었습니다!';
      case NetworkStatusType.loading:
        return '요청을 처리하는 중입니다...';
    }
  }

  /// 재시도 버튼 텍스트
  String get retryButtonText {
    switch (this) {
      case NetworkStatusType.networkError:
        return '재시도';
      case NetworkStatusType.apiError:
        return '다시 시도';
      default:
        return '확인';
    }
  }
}
