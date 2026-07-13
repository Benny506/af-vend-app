import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:medusa_admin/src/core/constants/strings.dart';
import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/error/medusa_error.dart';
import 'package:medusa_admin/src/core/utils/enums.dart';
import 'package:medusa_admin/src/features/auth/data/service/auth_preference_service.dart';
import 'package:medusa_admin/src/core/di/medusa_v1_client.dart';
import 'package:medusa_admin_dart_client/medusa_admin_dart_client_v2.dart';
import 'package:medusa_js_dart/medusa_js_dart.dart'
    hide User, Error, AuthenticationType, AdminAuthRes;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;





import 'package:multiple_result/multiple_result.dart';


@lazySingleton
class AuthenticationUseCase {

  AuthenticationUseCase(this._medusaAdminV2, this._medusav1, this._securePrefs);



  static AuthenticationUseCase get instance => getIt<AuthenticationUseCase>();

  AuthRepository get _authenticationRepository => _medusaAdminV2.auth;

  UsersRepository get _usersRepository => _medusaAdminV2.users;
  final MedusaAdminV2 _medusaAdminV2;
  final InterceptedMedusa _medusav1;
  final FlutterSecureStorage _securePrefs;





  Future<Result<String, MedusaError>> login(
      {required String email, required String password}) async {
    final medusaApiVersion = AuthPreferenceService.medusaApiVersionGetter;
    try {
      if (medusaApiVersion == MedusaApiVersion.v1) {
        final authType = AuthPreferenceService.authTypeGetter;
        if (authType == AuthenticationType.supabase) {
          log('Starting Supabase login for $email');
          final response = await sb.Supabase.instance.client.auth
              .signInWithPassword(email: email, password: password);
          if (response.session != null) {
            final token = response.session!.accessToken;
            await _securePrefs.write(key: AppConstants.supabaseTokenKey, value: token);
            _medusav1.setApiKey(token);
            return Success(token);
          }
          return Error(MedusaError(code: 'auth_error', type: 'Auth Error', message: 'Supabase login failed'));
        }


        log('Starting V1 login for $email');
        await _medusav1.admin.auth
            .createSession(AdminPostAuthReq(email, password))
            .timeout(const Duration(seconds: 30), onTimeout: () {
          log('V1 login timed out');
          throw DioException(
              requestOptions: RequestOptions(path: '/admin/auth'),
              type: DioExceptionType.connectionTimeout,
              message: 'Login timed out');
        });

        final token = _medusav1.getCookieToken();
        log('V1 token retrieved: ${token != null ? 'YES' : 'NO'}');
        if (token != null) {
          return Success('connect.sid=$token');
        }
        return Success('');
      }

      final user = await _authenticationRepository
          .authProvider('emailpass', {'email': email, 'password': password});


      if (user is Map<String, dynamic>) {
        return Success(user['token'] as String);
      }
      return Error(MedusaError(
            code: 'invalid_response',
            type: 'Invalid Response',
            message: 'The response from the server was not as expected.'));
    } on DioException catch (e) {
      return Error(MedusaError.fromHttp(
        status: e.response?.statusCode,
        body: e.response?.data,
        cause: e,
      ));
    } catch (error, stack) {
      log(error.toString());
      log(stack.toString());
      return Error(MedusaError(
          code: 'unknown', type: 'unknown', message: error.toString()));
    }
  }

  Future<Result<DeleteSessionRes, MedusaError>> logout() async {
    final medusaApiVersion = AuthPreferenceService.medusaApiVersionGetter;
    try {
      if (medusaApiVersion == MedusaApiVersion.v1) {
        final authType = AuthPreferenceService.authTypeGetter;
        if (authType == AuthenticationType.supabase) {
           await sb.Supabase.instance.client.auth.signOut();
           await _securePrefs.delete(key: AppConstants.supabaseTokenKey);
           _medusav1.setApiKey('');
           return const Success(DeleteSessionRes(success: true));
        }
        await _medusav1.admin.auth.deleteSession();
        _medusav1.setCookieToken('');
        return const Success(DeleteSessionRes(success: true));
      }




      final result = await _authenticationRepository.logout();
      return Success(result);

    } on DioException catch (e) {
      return Error(MedusaError.fromHttp(
        status: e.response?.statusCode,
        body: e.response?.data,
        cause: e,
      ));
    } catch (error, stack) {
      log(error.toString());
      log(stack.toString());
      return Error(MedusaError(
          code: 'unknown', type: 'unknown', message: error.toString()));
    }
  }

  Future<Result<SessionUser, MedusaError>> postSession(String token) async {
    try {
      final result =
          await _authenticationRepository.postSession('Bearer $token');
      return Success(result.user);
    } on DioException catch (e) {
      return Error(MedusaError.fromHttp(
        status: e.response?.statusCode,
        body: e.response?.data,
        cause: e,
      ));
    } catch (error, stack) {
      log(error.toString());
      log(stack.toString());
      return Error(MedusaError(
          code: 'unknown', type: 'unknown', message: error.toString()));
    }
  }

  Future<Result<User, MedusaError>> getCurrentUser({String? fields}) async {
    final medusaApiVersion = AuthPreferenceService.medusaApiVersionGetter;
    try {
      if (medusaApiVersion == MedusaApiVersion.v1) {
        final authType = AuthPreferenceService.authTypeGetter;
        if (authType == AuthenticationType.cookie &&
            _medusav1.getCookieToken() == null) {
          final cookie = await _securePrefs.read(key: AppConstants.cookieKey);
          if (cookie != null) {
            final token = cookie.split('=').last;
            _medusav1.setCookieToken(token);
          }
        } else if (authType == AuthenticationType.token &&
            _medusav1.getApiKey() == null) {
          final token = await _securePrefs.read(key: AppConstants.tokenKey);
          if (token != null) {
            _medusav1.setApiKey(token);
          }
        } else if (authType == AuthenticationType.supabase &&
            _medusav1.getApiKey() == null) {
          final token = await _securePrefs.read(key: AppConstants.supabaseTokenKey);
          if (token != null) {
            _medusav1.setApiKey(token);
          }
        }


        final result = await _medusav1.admin.auth.getSession();
        if (result.user != null) {
          final u = result.user!;
          return Success(User(
            id: u.id,
            email: u.email,
            firstName: u.firstName,
            lastName: u.lastName,
          ));
        }

      }




      final result = await _usersRepository.retrieveMe(fields: fields);
      return Success(result.user);

    } on DioException catch (e) {
      return Error(MedusaError.fromHttp(
        status: e.response?.statusCode,
        body: e.response?.data,
        cause: e,
      ));
    } catch (error, stack) {
      log(error.toString());
      log(stack.toString());
      return Error(MedusaError(
          code: 'unknown', type: 'unknown', message: error.toString()));
    }
  }
}
