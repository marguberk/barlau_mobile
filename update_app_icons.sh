#!/bin/bash

ICON_SRC="assets/images/applogo.png"

echo "🔄 Обновление иконок приложения..."

# Проверяем наличие applogo.png
if [ ! -f "$ICON_SRC" ]; then
    echo "❌ Файл $ICON_SRC не найден!"
    exit 1
fi

echo "✅ Найден файл applogo.png"

# Создаем временную папку для иконок
mkdir -p temp_icons

# Генерируем иконки разных размеров для Android
echo "📱 Генерация иконок для Android..."

if command -v magick &> /dev/null; then
    # Android иконки
    magick "$ICON_SRC" -resize 48x48 temp_icons/ic_launcher_48.png
    magick "$ICON_SRC" -resize 72x72 temp_icons/ic_launcher_72.png
    magick "$ICON_SRC" -resize 96x96 temp_icons/ic_launcher_96.png
    magick "$ICON_SRC" -resize 144x144 temp_icons/ic_launcher_144.png
    magick "$ICON_SRC" -resize 192x192 temp_icons/ic_launcher_192.png
    
    # iOS иконки
    magick "$ICON_SRC" -resize 20x20 temp_icons/Icon-App-20x20@1x.png
    magick "$ICON_SRC" -resize 40x40 temp_icons/Icon-App-20x20@2x.png
    magick "$ICON_SRC" -resize 60x60 temp_icons/Icon-App-20x20@3x.png
    magick "$ICON_SRC" -resize 29x29 temp_icons/Icon-App-29x29@1x.png
    magick "$ICON_SRC" -resize 58x58 temp_icons/Icon-App-29x29@2x.png
    magick "$ICON_SRC" -resize 87x87 temp_icons/Icon-App-29x29@3x.png
    magick "$ICON_SRC" -resize 40x40 temp_icons/Icon-App-40x40@1x.png
    magick "$ICON_SRC" -resize 80x80 temp_icons/Icon-App-40x40@2x.png
    magick "$ICON_SRC" -resize 120x120 temp_icons/Icon-App-40x40@3x.png
    magick "$ICON_SRC" -resize 120x120 temp_icons/Icon-App-60x60@2x.png
    magick "$ICON_SRC" -resize 180x180 temp_icons/Icon-App-60x60@3x.png
    magick "$ICON_SRC" -resize 76x76 temp_icons/Icon-App-76x76@1x.png
    magick "$ICON_SRC" -resize 152x152 temp_icons/Icon-App-76x76@2x.png
    magick "$ICON_SRC" -resize 167x167 temp_icons/Icon-App-83.5x83.5@2x.png
    magick "$ICON_SRC" -resize 1024x1024 temp_icons/Icon-App-1024x1024@1x.png
    
    echo "✅ Иконки сгенерированы с помощью ImageMagick (magick)"
else
    echo "⚠️  ImageMagick (magick) не найден. Копируем оригинальный файл..."
    cp "$ICON_SRC" temp_icons/ic_launcher.png
fi

# Копируем иконки в Android папки
echo "📱 Копирование иконок для Android..."

mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

if [ -f "temp_icons/ic_launcher_48.png" ]; then
    cp temp_icons/ic_launcher_48.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    cp temp_icons/ic_launcher_72.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    cp temp_icons/ic_launcher_96.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    cp temp_icons/ic_launcher_144.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    cp temp_icons/ic_launcher_192.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
else
    cp temp_icons/ic_launcher.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    cp temp_icons/ic_launcher.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    cp temp_icons/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    cp temp_icons/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    cp temp_icons/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
fi

# Копируем иконки в iOS папки
echo "🍎 Копирование иконок для iOS..."

mkdir -p ios/Runner/Assets.xcassets/AppIcon.appiconset

if [ -f "temp_icons/Icon-App-20x20@1x.png" ]; then
    cp temp_icons/Icon-App-*.png ios/Runner/Assets.xcassets/AppIcon.appiconset/
else
    cp temp_icons/ic_launcher.png ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
fi

# Обновляем Contents.json для iOS
cat > ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOF'
{
  "images" : [
    { "idiom" : "iphone", "scale" : "2x", "size" : "20x20" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "20x20" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "29x29" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "29x29" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "40x40" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "40x40" },
    { "idiom" : "iphone", "scale" : "2x", "size" : "60x60" },
    { "idiom" : "iphone", "scale" : "3x", "size" : "60x60" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "20x20" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "20x20" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "29x29" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "29x29" },
    { "idiom" : "ipad", "scale" : "1x", "size" : "40x40" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "40x40" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "76x76" },
    { "idiom" : "ipad", "scale" : "2x", "size" : "83.5x83.5" },
    { "idiom" : "ios-marketing", "scale" : "1x", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

# Очищаем временные файлы
rm -rf temp_icons

echo "✅ Иконки приложения обновлены!"
echo "📱 Android иконки обновлены в android/app/src/main/res/mipmap-*/"
echo "🍎 iOS иконки обновлены в ios/Runner/Assets.xcassets/AppIcon.appiconset/"
echo ""
echo "🔄 Для применения изменений перезапустите приложение:"
echo "   flutter clean && flutter pub get && flutter run" 
 
 
 
 