import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pam_p8_2026_ifs23038/data/models/api_response_model.dart';
import 'package:pam_p8_2026_ifs23038/providers/auth_provider.dart';
import '../helpers/test_fakes.dart';

void main() {
  group('AuthProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('init tanpa token mengubah status menjadi unauthenticated', () async {
      final repository = FakeAuthRepository();
      final provider = AuthProvider(repository: repository);

      await provider.init();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.authToken, isNull);
    });

    test('login sukses menyimpan token dan memuat profil', () async {
      final repository = FakeAuthRepository()
        ..loginResponse = const ApiResponse(
          success: true,
          message: 'OK',
          data: {'authToken': 'auth-123', 'refreshToken': 'refresh-123'},
        )
        ..getMeQueue.add(
          ApiResponse(
            success: true,
            message: 'OK',
            data: makeUser(name: 'Budi'),
          ),
        );

      final provider = AuthProvider(repository: repository);
      final success = await provider.login(
        username: 'budi',
        password: 'secret',
      );

      final prefs = await SharedPreferences.getInstance();

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.user?.name, 'Budi');
      expect(prefs.getString('authToken'), 'auth-123');
      expect(prefs.getString('refreshToken'), 'refresh-123');
      expect(repository.lastLoginUsername, 'budi');
    });

    test('init dengan token tersimpan langsung memuat profil', () async {
      SharedPreferences.setMockInitialValues({
        'authToken': 'saved-auth',
        'refreshToken': 'saved-refresh',
      });

      final repository = FakeAuthRepository()
        ..getMeQueue.add(
          ApiResponse(
            success: true,
            message: 'OK',
            data: makeUser(name: 'Saved User'),
          ),
        );

      final provider = AuthProvider(repository: repository);
      await provider.init();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.name, 'Saved User');
      expect(repository.lastGetMeAuthToken, 'saved-auth');
    });

    test('updateProfile sukses memperbarui user via loadProfile', () async {
      final repository = FakeAuthRepository()
        ..loginResponse = const ApiResponse(
          success: true,
          message: 'OK',
          data: {'authToken': 'auth-123', 'refreshToken': 'refresh-123'},
        )
        ..getMeQueue.add(
          ApiResponse(
            success: true,
            message: 'OK',
            data: makeUser(name: 'Awal', username: 'awal'),
          ),
        )
        ..updateMeResponse = const ApiResponse(success: true, message: 'OK')
        ..getMeQueue.add(
          ApiResponse(
            success: true,
            message: 'OK',
            data: makeUser(name: 'Baru', username: 'baru'),
          ),
        );

      final provider = AuthProvider(repository: repository);
      await provider.login(username: 'awal', password: 'secret');
      final success = await provider.updateProfile(
        name: 'Baru',
        username: 'baru',
      );

      expect(success, isTrue);
      expect(provider.user?.name, 'Baru');
      expect(provider.user?.username, 'baru');
      expect(repository.lastUpdateName, 'Baru');
      expect(repository.lastUpdateUsername, 'baru');
    });

    test(
      'updatePassword gagal mengembalikan false dan menyimpan error message',
      () async {
        final repository = FakeAuthRepository()
          ..loginResponse = const ApiResponse(
            success: true,
            message: 'OK',
            data: {'authToken': 'auth-123', 'refreshToken': 'refresh-123'},
          )
          ..getMeQueue.add(
            ApiResponse(success: true, message: 'OK', data: makeUser()),
          )
          ..updatePasswordResponse = const ApiResponse(
            success: false,
            message: 'Password lama salah.',
          );

        final provider = AuthProvider(repository: repository);
        await provider.login(username: 'tester', password: 'secret');
        final success = await provider.updatePassword(
          currentPassword: 'wrong',
          newPassword: 'new-password',
        );

        expect(success, isFalse);
        expect(provider.errorMessage, 'Password lama salah.');
        expect(provider.status, AuthStatus.authenticated);
      },
    );

    test(
      'updatePhoto mengirim Uint8List ke repository dan refresh profil',
      () async {
        final repository = FakeAuthRepository()
          ..loginResponse = const ApiResponse(
            success: true,
            message: 'OK',
            data: {'authToken': 'auth-123', 'refreshToken': 'refresh-123'},
          )
          ..getMeQueue.add(
            ApiResponse(
              success: true,
              message: 'OK',
              data: makeUser(urlPhoto: null),
            ),
          )
          ..updatePhotoResponse = const ApiResponse(
            success: true,
            message: 'OK',
          )
          ..getMeQueue.add(
            ApiResponse(
              success: true,
              message: 'OK',
              data: makeUser(urlPhoto: 'https://cdn.example.com/photo.jpg'),
            ),
          );

        final provider = AuthProvider(repository: repository);
        await provider.login(username: 'tester', password: 'secret');

        final bytes = Uint8List.fromList([10, 20, 30, 40]);
        final success = await provider.updatePhoto(
          imageBytes: bytes,
          imageFilename: 'avatar.jpg',
        );

        expect(success, isTrue);
        expect(repository.lastUpdatePhotoFilename, 'avatar.jpg');
        expect(repository.lastUpdatePhotoBytes, orderedEquals(bytes));
        expect(provider.user?.urlPhoto, 'https://cdn.example.com/photo.jpg');
      },
    );
  });
}
