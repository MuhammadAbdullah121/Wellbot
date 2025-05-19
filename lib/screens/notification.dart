import 'package:flutter/material.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/notifications/notification_manager.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final NotificationManager _notificationManager = NotificationManager();

  String _dailyQuote = "";
  bool _isLoadingQuote = true;

  // Gemini API configuration
  static const String _apiKey = 'AIzaSyCxlb7pIUnNk2D1HHvRA5JOMjl4znn-5jg'; // Use the same key from diet and fitness
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _notificationManager.addListener(_onNotificationUpdate);
    _loadDailyQuote();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationManager.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    setState(() {});
  }

  // Gemini API methods integrated directly
  Future<String> _generateMotivationalQuote() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Generate a single inspirational motivational quote. Return only the quote with the author name in this format: "Quote text - Author Name". Do not add any explanation, commentary, or additional text.'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 100,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String quote = data['candidates'][0]['content']['parts'][0]['text'];

        // Clean the quote using regex
        quote = _cleanQuote(quote);

        return quote;
      } else {
        throw Exception('Failed to generate quote: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating quote: $e');
      // Return a fallback quote if API fails
      return _getFallbackQuote();
    }
  }

  String _cleanQuote(String rawQuote) {
    // First, basic cleaning
    String cleaned = rawQuote
        .replaceAll(RegExp(r'\*+'), '') // Remove asterisks
        .replaceAll(RegExp(r'#+'), '') // Remove hash symbols
        .replaceAll(RegExp(r'_+'), '') // Remove underscores
        .replaceAll(RegExp(r'`+'), '') // Remove backticks
        .replaceAll(RegExp(r'\n+'), ' ') // Replace newlines with spaces
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();

    // Remove common AI response prefixes
    List<String> prefixes = [
      'Here\'s a motivational quote:',
      'Here is a motivational quote:',
      'Here\'s an inspirational quote:',
      'Here is an inspirational quote:',
      'Quote:',
      'Motivational quote:',
    ];

    for (String prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix.toLowerCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
        break;
      }
    }

    // Remove common suffixes
    List<String> suffixes = [
      'I hope this helps',
      'Hope this helps',
      'Let me know if you need more',
    ];

    for (String suffix in suffixes) {
      if (cleaned.toLowerCase().contains(suffix.toLowerCase())) {
        int index = cleaned.toLowerCase().indexOf(suffix.toLowerCase());
        cleaned = cleaned.substring(0, index).trim();
        break;
      }
    }

    // Remove leading and trailing quotes using simple string operations
    while (cleaned.startsWith('"') || cleaned.startsWith("'") || cleaned.startsWith('`')) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith('"') || cleaned.endsWith("'") || cleaned.endsWith('`')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    cleaned = cleaned.trim();

    // If the quote doesn't have an author format, return a fallback
    if (!cleaned.contains(' - ') || cleaned.length < 10) {
      return _getFallbackQuote();
    }

    return cleaned;
  }

  String _getFallbackQuote() {
    final List<String> fallbackQuotes = [
      "The only way to do great work is to love what you do. - Steve Jobs",
      "Life is what happens to you while you're busy making other plans. - John Lennon",
      "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
      "It is during our darkest moments that we must focus to see the light. - Aristotle",
      "Success is not final, failure is not fatal: it is the courage to continue that counts. - Winston Churchill",
    ];

    final now = DateTime.now();
    return fallbackQuotes[now.day % fallbackQuotes.length];
  }

  Future<void> _loadDailyQuote() async {
    try {
      // Check if we already have today's quote cached
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastQuoteDate = prefs.getString('last_quote_date') ?? '';
      final cachedQuote = prefs.getString('daily_quote') ?? '';

      if (lastQuoteDate == today && cachedQuote.isNotEmpty) {
        // Use cached quote for today
        setState(() {
          _dailyQuote = cachedQuote;
          _isLoadingQuote = false;
        });
      } else {
        // Generate new quote for today
        final quote = await _generateMotivationalQuote();
        await prefs.setString('daily_quote', quote);
        await prefs.setString('last_quote_date', today);

        setState(() {
          _dailyQuote = quote;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      print('Error loading daily quote: $e');
      setState(() {
        _dailyQuote = "The only way to do great work is to love what you do. - Steve Jobs";
        _isLoadingQuote = false;
      });
    }
  }

  Future<void> _refreshQuote() async {
    setState(() {
      _isLoadingQuote = true;
    });

    try {
      final quote = await _generateMotivationalQuote();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('daily_quote', quote);
      await prefs.setString('last_quote_date', DateFormat('yyyy-MM-dd').format(DateTime.now()));

      setState(() {
        _dailyQuote = quote;
        _isLoadingQuote = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quote refreshed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoadingQuote = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh quote'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          elevation: 0,
          title: Text(
            "Notifications",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_notificationManager.notifications.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear_all, color: Colors.white),
                onPressed: () {
                  _showClearAllDialog();
                },
              ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshQuote,
            ),
          ],
        ),
        body: Responsive(
          mobile: _buildMobileContent(context),
          tablet: _buildTabletContent(context),
          desktop: _buildDesktopContent(context),
        ),
      ),
    );
  }

  Widget _buildMobileContent(BuildContext context) {
    return _buildNotificationContent(context, isMobile: true);
  }

  Widget _buildTabletContent(BuildContext context) {
    return _buildNotificationContent(context);
  }

  Widget _buildDesktopContent(BuildContext context) {
    return _buildNotificationContent(context, isDesktop: true);
  }

  Widget _buildNotificationContent(BuildContext context, {bool isMobile = false, bool isDesktop = false}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 50.0 : isMobile ? 16.0 : 24.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDailyQuoteCard(),
                SizedBox(height: 20),
                if (_notificationManager.notifications.isEmpty)
                  _buildEmptyState()
                else
                  _buildNotificationsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyQuoteCard() {
    final today = DateTime.now();

    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Daily Inspiration",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isLoadingQuote)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 15),
              _isLoadingQuote
                  ? Container(
                height: 60,
                child: Center(
                  child: Text(
                    "Generating your daily inspiration...",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
                  : Text(
                _dailyQuote,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormat('MMMM dd, yyyy').format(today),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              "No Notifications",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You're all caught up! No new notifications to display.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Group notifications by screen
    Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
    for (var notification in _notificationManager.notifications) {
      String screen = notification['screen'] ?? 'General';
      groupedNotifications.putIfAbsent(screen, () => []);
      groupedNotifications[screen]!.add(notification);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notifications by Screen",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 15),
        ...groupedNotifications.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...entry.value.map((notification) {
                int globalIndex = _notificationManager.notifications.indexOf(notification);
                return _buildNotificationCard(notification, globalIndex);
              }).toList(),
              SizedBox(height: 10),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification['type']).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: _getNotificationColor(notification['type']),
            size: 24,
          ),
        ),
        title: Text(
          notification['title'],
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              notification['message'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  notification['time'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    notification['screen'] ?? 'General',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: notification['isRead'] ? null : Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            shape: BoxShape.circle,
          ),
        ),
        onTap: () {
          _notificationManager.markAsRead(index);
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'reminder':
        return Colors.orange;
      case 'achievement':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'warning':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'reminder':
        return Icons.alarm;
      case 'achievement':
        return Icons.star;
      case 'update':
        return Icons.system_update;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Clear All Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to clear all notifications? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _clearAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearAllNotifications() {
    _notificationManager.clearAllNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }
}