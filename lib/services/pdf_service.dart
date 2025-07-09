import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFService {
  static const String baseUrl = 'https://barlau.org';
  
  // Упрощенный метод - открываем PDF в браузере
  static Future<bool> openEmployeePDF(int employeeId) async {
    try {
      final pdfUrl = '$baseUrl/public/employees/$employeeId/pdf/';
      final uri = Uri.parse(pdfUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        print('Не удалось открыть URL: $pdfUrl');
        return false;
      }
    } catch (e) {
      print('Ошибка при открытии PDF: $e');
      return false;
    }
  }

  // Альтернативный метод для скачивания (если понадобится в будущем)
  static Future<bool> downloadEmployeePDF(int employeeId, String employeeName) async {
    try {
      // Запрашиваем разрешения для Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            return false;
          }
        }
      }

      // Получаем директорию для сохранения
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        print('Не удалось получить директорию для сохранения');
        return false;
      }

      // Создаем папку Downloads если её нет
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Формируем имя файла
      final fileName = '${employeeName.replaceAll(' ', '_')}_resume.pdf';
      final filePath = '${downloadsDir.path}/$fileName';

      // Создаем Dio клиент
      final dio = Dio();
      
      // Скачиваем PDF
      final response = await dio.download(
        '$baseUrl/api/public/employees/$employeeId/pdf/',
        filePath,
        options: Options(
          headers: {
            'Accept': 'application/pdf',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            print('Скачивание: $progress%');
          }
        },
      );

      if (response.statusCode == 200) {
        print('PDF успешно скачан: $filePath');
        return true;
      } else {
        print('Ошибка скачивания: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Ошибка при скачивании PDF: $e');
      return false;
    }
  }

  // Метод для получения веб URL PDF
  static String getEmployeePDFUrl(int employeeId) {
    return '$baseUrl/employees/$employeeId/pdf/';
  }

  // Метод для получения API URL PDF
  static String getEmployeePDFApiUrl(int employeeId) {
    return '$baseUrl/api/employees/$employeeId/pdf/';
  }
} 