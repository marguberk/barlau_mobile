import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class WebCompatibleImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? placeholderType; // 'truck', 'gallery', 'avatar', etc.

  const WebCompatibleImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.placeholderType,
  });

  @override
  State<WebCompatibleImage> createState() => _WebCompatibleImageState();
}

class _WebCompatibleImageState extends State<WebCompatibleImage> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('WebCompatibleImage: Загружаем изображение ${widget.imageUrl} (${kIsWeb ? 'WEB' : 'MOBILE'})');
    }

    // Для веб-версии используем специальную логику
    if (kIsWeb) {
      return _buildWebImage();
    }

    // Для мобильных платформ используем стандартный подход
    return _buildMobileImage();
  }

  Widget _buildWebImage() {
    if (_hasError) {
      // Если произошла ошибка, показываем красивую заглушку
      return _buildStyledPlaceholder();
    }

    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Изображение загружено успешно
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });
          return child;
        }
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('WebCompatibleImage: CORS ошибка для ${widget.imageUrl}: $error');
          print('WebCompatibleImage: Показываем стильную заглушку вместо изображения');
        }
        
        // Устанавливаем флаг ошибки и перерисовываем
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasError) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        });
        
        return _buildStyledPlaceholder();
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }

  Widget _buildMobileImage() {
    return Image.network(
      widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('WebCompatibleImage: Ошибка загрузки ${widget.imageUrl}: $error');
        }
        return _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ?? 
      Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2679DB),
            strokeWidth: 2,
          ),
        ),
      );
  }

  Widget _buildStyledPlaceholder() {
    // Определяем тип заглушки на основе размеров или явно указанного типа
    String type = widget.placeholderType ?? _inferPlaceholderType();
    
    switch (type) {
      case 'gallery':
        return _buildGalleryPlaceholder();
      case 'list':
        return _buildListPlaceholder();
      default:
        return _buildTruckPlaceholder();
    }
  }

  String _inferPlaceholderType() {
    // Определяем тип на основе размеров
    final width = widget.width ?? 100;
    final height = widget.height ?? 100;
    
    if (width < 120 && height < 120) {
      return 'list'; // Маленькие изображения в списке
    } else if (width == height) {
      return 'gallery'; // Квадратные изображения в галерее
    }
    return 'truck'; // По умолчанию
  }

  Widget _buildGalleryPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2679DB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.photo_camera,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildListPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2679DB),
            Color(0xFF1E40AF),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.local_shipping,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTruckPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2679DB),
            Color(0xFF1E40AF),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2679DB).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Фото грузовика',
              style: TextStyle(
    fontFamily: 'SF Pro Display',
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
      Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: Color(0xFF9CA3AF),
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'Изображение\nне загружено',
              textAlign: TextAlign.center,
              style: TextStyle(
    fontFamily: 'SF Pro Display',
                color: Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
  }
} 