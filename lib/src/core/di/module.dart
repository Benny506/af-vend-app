import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:medusa_admin/src/core/routing/app_router.dart';
import 'package:medusa_admin/src/features/auth/data/service/auth_preference_service.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_js_dart/medusa_js_dart.dart';
import 'package:medusa_admin/src/core/di/medusa_admin_di.dart';
import 'package:medusa_admin/src/core/di/medusa_v1_client.dart';
import 'package:medusa_admin/src/core/di/medusa_v1_transformer.dart';


@module
abstract class RegisterCoreDependencies {
  @singleton
  AppRouter appRouter() => AppRouter();




  @singleton
  FlutterSecureStorage securePrefs() => FlutterSecureStorage(aOptions: _getAndroidOptions());

  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @preResolve
  Future<PackageInfo> get packageInfo => PackageInfo.fromPlatform();

  @singleton
  InterceptedMedusa v1Client(AuthPreferenceService authPreferenceService) {
    final dio = Dio(BaseOptions(baseUrl: authPreferenceService.baseUrl ?? ''));
    dio.interceptors.add(MedusaV1ResponseTransformer());
    dio.interceptors.add(MedusaAdminDi.authInterceptor);
    dio.interceptors.add(MedusaAdminDi.loggerInterceptor);

    return InterceptedMedusa(
      Configuration(
        baseUrl: authPreferenceService.baseUrl ?? '',
        maxRetries: 3,
        customHeaders: {
          "sb-access-token": "",
        },
      ),
      dio,
    );
  }



  @singleton
  MedusaAdminV2 v2Client(AuthPreferenceService authPreferenceService) {
    return MedusaAdminV2.initialize(
      baseUrl: authPreferenceService.baseUrl ?? '',
      interceptors: [
        MedusaV1ResponseTransformer(),
        MedusaAdminDi.loggerInterceptor,
        MedusaAdminDi.authInterceptor,
      ],
    );


  }


}

AndroidOptions _getAndroidOptions() => const AndroidOptions();
