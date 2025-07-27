import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

class SvgIcon extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final Color? color;

  const SvgIcon({
    super.key,
    required this.assetName,
    this.width,
    this.height,
    this.color,
  });

  // Маппинг SVG файлов на Material Icons для fallback
  IconData _getMaterialIcon(String assetName) {
    switch (assetName) {
      case 'home.svg':
        return Icons.home;
      case 'truck.svg':
        return Icons.local_shipping;
      case 'employee.svg':
        return Icons.people;
      case 'task.svg':
        return Icons.assignment;
      case 'receipt.svg':
        return Icons.receipt;
      case 'location.svg':
        return Icons.location_on;
      case 'check-square.svg':
        return Icons.check_box;
      case 'eye.svg':
        return Icons.visibility;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = 'assets/images/$assetName';
    final iconSize = width ?? height ?? 24.0;
    final iconColor = color ?? Theme.of(context).iconTheme.color;
    
    // Пытаемся использовать SVG для всех платформ
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (context) {
        // Показываем Material Icon как placeholder
        return Icon(
          _getMaterialIcon(assetName),
          size: iconSize,
          color: iconColor,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // В случае ошибки показываем Material Icon
        if (kDebugMode) {
          print('SvgIcon: Fallback to Material Icon for $assetName (${kIsWeb ? 'WEB' : 'MOBILE'}): $error');
        }
        return Icon(
          _getMaterialIcon(assetName),
          size: iconSize,
          color: iconColor,
        );
      },
    );
  }
} 