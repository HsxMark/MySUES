import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AcademicClient {
  static const String defaultBaseUrl = 'https://jxfw.sues.edu.cn';
  late Dio _dio;
  late CookieJar _cookieJar;

  AcademicClient({String baseUrl = defaultBaseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      followRedirects: true,
      validateStatus: (status) => status != null && status < 400, // Treat redirects as success to follow them manually if needed or let Dio handle
    ));
    _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(storage: FileStorage("$appDocPath/.cookies/"));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<bool> login(String username, String password) async {
    try {
      // 1. First, access the login page to get any initial cookies/CSFR tokens if needed
      // Most QiangZhi systems work better if you visit the page first
      await _dio.get('/student/sso/login');

      // 2. Post credentials
      // Note: "QiangZhi" systems usually use form-urlencoded
      final Response response = await _dio.post(
        '/student/sso/login',
        data: {
          'username': username,
          'password': password,
          // 'code': '', // User mentioned no verification code
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status! < 500,
        ),
      );

      // Check success. Usually redirects to /student/home or generic success message
      // If we get a 302 to /student/home, or if we are effectively redirected there
      if (response.realUri.toString().contains('/student/home') || 
          response.data.toString().contains('退出') || 
          response.statusCode == 302) {
        return true;
      }
      
      // Sometimes it returns JSON {result: "success"} or similar
      if (response.data.toString().contains('"result":"1"') || 
          response.data.toString().contains('success')) {
        return true;
      }

      return false;

    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Fetch Course Table HTML
  // Usually at /student/course/table/list or similar. 
  // We'll try the likely URL for the current semester.
  Future<String?> fetchCourseTableHtml() async {
    try {
      // This URL often returns the time table VIEW
      // Assuming SUES uses standard QiangZhi path
      final response = await _dio.get('/student/coure/course_table/wdkb');
      return response.data;
    } catch (e) {
      print('Fetch course error: $e');
      return null;
    }
  }

  // Fetch Scores HTML
  // Likely paths: /student/integratedQuery/score/course/attend/list
  Future<String?> fetchScoreHtml() async {
    try {
      // We often need to "search" to get the list. 
      // Sometimes a GET to the query page is enough if it defaults to all.
      // Or we might need to POST empty params.
      final response = await _dio.get('/student/integratedQuery/score/course/attend/list');
      return response.data;
    } catch (e) {
      print('Fetch score error: $e');
      return null;
    }
  }

  // Fetch Exams HTML
  // Likely paths: /student/exam/arrange/list
  Future<String?> fetchExamHtml() async {
    try {
      final response = await _dio.get('/student/exam/arrange/list');
      return response.data;
    } catch (e) {
      print('Fetch exam error: $e');
      return null;
    }
  }

  Future<String?> fetchHtmlWithCookie(String url, String cookie) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Cookie': cookie},
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        )
      );
      return response.data.toString();
    } catch (e) {
      print('Fetch error: $e');
      return null;
    }
  }

  Future<String?> postHtmlWithCookie(String url, String cookie, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: {
            'Cookie': cookie,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        )
      );
      return response.data.toString();
    } catch (e) {
      print('Post error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _dio.get('/student/logout');
    await _cookieJar.deleteAll();
  }
}
