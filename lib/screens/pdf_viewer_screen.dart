import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/app_header.dart';

class PDFViewerScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const PDFViewerScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late WebViewController controller;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void dispose() {
    // Очищаем ресурсы WebView
    super.dispose();
  }

  void _initializeWebView() {
    final resumeUrl = 'https://barlau.org/public/employees/${widget.employeeId}/pdf/';
    print('Инициализируем WebView для URL: $resumeUrl');
    
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1')
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView прогресс: $progress%');
          },
          onPageStarted: (String url) {
            print('WebView начал загрузку: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            print('WebView завершил загрузку: $url');
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              
              // Применяем финальные настройки после полной загрузки
              Future.delayed(const Duration(milliseconds: 500), () {
                controller.runJavaScript('''
                  // Убираем горизонтальную прокрутку
                  document.body.style.overflowX = 'hidden';
                  document.documentElement.style.overflowX = 'hidden';
                  
                                     // Применяем настройки если еще не применены
                   if (window.innerWidth < 768 && !document.body.style.transform.includes('scale')) {
                     document.body.style.transform = 'scale(0.55)';
                     document.body.style.transformOrigin = 'top left';
                     document.body.style.width = '181.82%';
                   }
                ''');
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView ошибка: ${error.description}');
            if (mounted) {
              setState(() {
                isLoading = false;
                errorMessage = 'Ошибка загрузки: ${error.description}';
              });
            }
          },
        ),
      );
    
    // Загружаем URL
    controller.loadRequest(Uri.parse(resumeUrl)).then((_) {
      // После загрузки страницы добавляем CSS для мобильной адаптации
      Future.delayed(const Duration(milliseconds: 1000), () {
        controller.runJavaScript('''
          // Добавляем viewport meta tag если его нет
          if (!document.querySelector('meta[name="viewport"]')) {
            var viewport = document.createElement('meta');
            viewport.name = 'viewport';
            viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            document.getElementsByTagName('head')[0].appendChild(viewport);
          }
          
          // Добавляем стили для мобильной адаптации с сохранением А4 формата
          var style = document.createElement('style');
          style.innerHTML = `
            /* Основные настройки для мобильного просмотра */
            body {
              margin: 0 !important;
              padding: 0 !important;
              overflow-x: hidden !important;
              width: 100% !important;
            }
            
            html {
              overflow-x: hidden !important;
              width: 100% !important;
            }
            
            /* Контейнер резюме - сохраняем пропорции А4 */
            .resume-container, .container, .page {
              max-width: 100% !important;
              margin: 0 auto !important;
              padding: 0 !important;
              box-sizing: border-box !important;
              background: white !important;
            }
            
            /* Обеспечиваем правильное отображение всех элементов */
            * {
              box-sizing: border-box !important;
            }
            
            .main-content, .content, .resume-content {
              width: 100% !important;
              max-width: 100% !important;
            }
            
            /* Корректируем пропорции колонок */
            .left-column, .sidebar, .contact-section {
              width: 40% !important;
              min-width: 40% !important;
              flex: 0 0 40% !important;
            }
            
            .right-column, .main-section, .content-section {
              width: 60% !important;
              min-width: 60% !important;
              flex: 0 0 60% !important;
            }
            
            /* Если используется CSS Grid */
            .resume-grid, .cv-grid {
              grid-template-columns: 40% 60% !important;
            }
            
            /* Если используется flexbox */
            .resume-container, .cv-container {
              display: flex !important;
              flex-direction: row !important;
            }
            
            /* Дополнительные селекторы для разных структур */
            .col-md-4, .col-4, .w-1\\/3 {
              width: 40% !important;
              flex: 0 0 40% !important;
            }
            
            .col-md-8, .col-8, .w-2\\/3 {
              width: 60% !important;
              flex: 0 0 60% !important;
            }
            
            /* Поиск по цвету фона для синей колонки */
            [style*="background-color: #2679DB"], 
            [style*="background: #2679DB"],
            .bg-blue, .bg-primary {
              width: 40% !important;
              min-width: 40% !important;
              flex: 0 0 40% !important;
            }
            
            /* Скрываем элементы печати */
            .print-only, .no-print {
              display: none !important;
            }
            
                         /* Адаптируем для мобильного просмотра */
             @media screen and (max-width: 768px) {
               body {
                 transform: scale(0.55) !important;
                 transform-origin: top left !important;
                 width: 181.82% !important;
                 font-size: inherit !important;
               }
               
               .resume-container, .container, .page {
                 width: 100% !important;
                 max-width: none !important;
                 margin: 0 !important;
                 padding: 0 !important;
                 box-sizing: border-box !important;
               }
               
               /* Убираем все переопределения размеров */
               h1, h2, h3, h4, h5, h6 {
                 font-size: inherit !important;
                 margin: inherit !important;
               }
               
               .profile-photo, img {
                 width: inherit !important;
                 height: inherit !important;
               }
               
               .contact-info {
                 font-size: inherit !important;
               }
               
               .section {
                 margin: inherit !important;
               }
             }
          `;
          document.head.appendChild(style);
          
                     // Применяем настройки для мобильных устройств
           if (window.innerWidth < 768) {
             document.body.style.transform = 'scale(0.55)';
             document.body.style.transformOrigin = 'top left';
             document.body.style.width = '181.82%';
             
             // Ищем и корректируем колонки резюме
             setTimeout(() => {
               // Поиск синей колонки по цвету фона
               const blueElements = Array.from(document.querySelectorAll('*')).filter(el => {
                 const style = window.getComputedStyle(el);
                 const bgColor = style.backgroundColor;
                 return bgColor.includes('rgb(38, 121, 219)') || bgColor.includes('#2679DB');
               });
               
               blueElements.forEach(el => {
                 if (el.offsetWidth > 100) { // Только крупные элементы
                   el.style.width = '40%';
                   el.style.minWidth = '40%';
                   el.style.flex = '0 0 40%';
                 }
               });
               
               // Поиск белых колонок рядом с синими
               blueElements.forEach(blueEl => {
                 const parent = blueEl.parentElement;
                 if (parent) {
                   const siblings = Array.from(parent.children);
                   siblings.forEach(sibling => {
                     if (sibling !== blueEl && sibling.offsetWidth > 100) {
                       sibling.style.width = '60%';
                       sibling.style.minWidth = '60%';
                       sibling.style.flex = '0 0 60%';
                     }
                   });
                 }
               });
             }, 100);
           }
        ''');
      });
    }).catchError((error) {
      print('Ошибка загрузки URL: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Не удалось загрузить страницу: $error';
        });
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppHeader(
        title: 'PDF Резюме',
        isConnected: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6B7280),
          ),
        ),
        showNotificationIcon: false,
        showProfileIcon: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                // Добавляем JavaScript для печати страницы
                controller.runJavaScript('window.print();');
              },
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2679DB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.print,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о документе
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Резюме: ${widget.employeeName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите на иконку печати для сохранения в PDF',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Web Viewer
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2679DB),
            ),
            SizedBox(height: 16),
            Text(
              'Загрузка резюме...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _initializeWebView();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2679DB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Попробовать снова'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = 'https://barlau.org/public/employees/${widget.employeeId}/pdf/';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Не удалось открыть браузер'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2679DB),
                      side: const BorderSide(color: Color(0xFF2679DB)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Открыть в браузере'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: controller);
  }
} 