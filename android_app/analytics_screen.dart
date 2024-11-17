import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Импорт пакета кэширования

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Map<String, String>> _articles = [];
  bool _isLoading = true;
  final _cacheManager = DefaultCacheManager(); // Инициализация кэш-менеджера

  @override
  void initState() {
    super.initState();
    _fetchRSSFeed();
  }

  Future<void> _fetchRSSFeed() async {
    final cacheKey = 'analytics_rss_feed';
    final cachedData = await _cacheManager.getFileFromCache(cacheKey);

    if (cachedData != null) {
      // Использование закэшированных данных
      final fileContent = await cachedData.file.readAsString();
      _parseRSSFeed(fileContent);
    } else {
      // Загрузка данных с сервера
      final response = await http.get(Uri.parse('https://forklog.com/tag/prognozy/feed/'));
      if (response.statusCode == 200) {
        await _cacheManager.putFile(cacheKey, response.bodyBytes); // Кэширование ответа
        _parseRSSFeed(response.body);
      } else {
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to load RSS feed');
      }
    }
  }

  Future<void> _refreshData() async {
    // При обновлении удаляем кэш и заново загружаем данные
    final cacheKey = 'analytics_rss_feed';
    await _cacheManager.removeFile(cacheKey);
    await _fetchRSSFeed();
  }

  void _parseRSSFeed(String responseBody) {
    final document = xml.XmlDocument.parse(responseBody);
    final items = document.findAllElements('item');
    setState(() {
      _articles = items.map((item) {
        final title = item.findElements('title').single.text;
        final link = item.findElements('link').single.text;
        final pubDate = item.findElements('pubDate').single.text;
        final description = item.findElements('description').single.text;
        return {
          'title': title,
          'link': link,
          'pubDate': pubDate,
          'description': description
        };
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bitcoin Analytics'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshData, // Добавлен RefreshIndicator
        child: ListView.builder(
          itemCount: _articles.length,
          itemBuilder: (context, index) {
            final article = _articles[index];
            return Card(
              margin: EdgeInsets.all(10.0),
              child: ListTile(
                title: Text(article['title']!),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article['pubDate']!),
                    HtmlWidget(
                      article['description']!,
                      onTapUrl: (url) async {
                        if (await canLaunch(url)) {
                          await launch(url);
                          return true;
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    ),
                  ],
                ),
                onTap: () => _launchURL(article['link']!),
              ),
            );
          },
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
