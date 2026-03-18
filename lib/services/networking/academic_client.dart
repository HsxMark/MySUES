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
      validateStatus: (status) => status != null && status < 400, 
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
      
      
      await _dio.get('/student/sso/login');

      
      
      final Response response = await _dio.post(
        '/student/sso/login',
        data: {
          'username': username,
          'password': password,
          
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (status) => status! < 500,
        ),
      );

      
      
      if (response.realUri.toString().contains('/student/home') || 
          response.data.toString().contains('退出') || 
          response.statusCode == 302) {
        return true;
      }
      
      
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

  
  
  
  Future<String?> fetchCourseTableHtml() async {
    try {
      
      
      final response = await _dio.get('/student/coure/course_table/wdkb');
      return response.data;
    } catch (e) {
      print('Fetch course error: $e');
      return null;
    }
  }

  
  
  Future<String?> fetchScoreHtml() async {
    try {
      
      
      
      final response = await _dio.get('/student/integratedQuery/score/course/attend/list');
      return response.data;
    } catch (e) {
      print('Fetch score error: $e');
      return null;
    }
  }

  
  
  Future<String?> fetchExamHtml() async {
    try {
      final response = await _dio.get('/student/exam/arrange/list');
      return response.data;
    } catch (e) {
      print('Fetch exam error: $e');
      return null;
    }
  }

  Future<String?> fetchHtmlWithCookie(String url, String cookie, {Map<String, String>? headers}) async {
    try {
      final Map<String, dynamic> requestHeaders = {'Cookie': cookie};
      if (headers != null) {
        requestHeaders.addAll(headers);
      }
      
      final response = await _dio.get(
        url,
        options: Options(
          headers: requestHeaders,
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

  Future<String?> postHtmlWithCookie(String url, String cookie, {Map<String, dynamic>? data, Map<String, String>? headers}) async {
    try {
      final Map<String, dynamic> requestHeaders = {
        'Cookie': cookie,
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: requestHeaders,
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
