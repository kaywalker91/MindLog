import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 앱 아이콘 리소스 유틸리티
class AppIcons {
  static const String _svgIcon = '''
    <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
      <!-- 배경 -->
      <circle cx="50" cy="50" r="48" fill="#4A90E2" stroke="#3A7BC8" stroke-width="2"/>
      
      <!-- 메인 심장 -->
      <path d="M50 25 C45 25 35 35 35 45 C35 50 45 55 50 55 C55 55 65 55 70 50 C75 45 85 35 85 25 C85 15 75 5 65 5 C60 5 50 15 50 25" 
            fill="#FFFFFF" stroke="#4A90E2" stroke-width="2"/>
      
      <!-- 하트 아이콘 -->
      <path d="M50 45 L50 65 M35 45 L65 45 M35 55 L65 55" 
            stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
      
      <!-- 윗쪽 선 장식 -->
      <path d="M50 15 C50 15 47 17 45 20 L55 30 C52 23 50 25 50 25" 
            stroke="#4A90E2" stroke-width="2" stroke-linecap="round"/>
      
      <!-- 반응 챔 -->
      <path d="M30 50 C30 50 70 50 70 50" 
            stroke="#4A90E2" stroke-width="2" stroke-linecap="round"/>
      <path d="M30 55 L70 55 M30 65 L70 65" 
            stroke="#4A90E2" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      
      <!-- 감정표시 -->
      <circle cx="25" cy="30" r="3" fill="#FF9800"/>
      <circle cx="75" cy="30" r="3" fill="#4CAF50"/>
      <circle cx="25" cy="70" r="3" fill="#2196F3"/>
    </svg>
  ''';

  /// SVG 아이콘 반환
  static Widget getSvgIcon({double? size, Color? color}) {
    return SvgPicture.string(
      _svgIcon,
      width: size ?? 50,
      height: size ?? 50,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
    );
  }
}
