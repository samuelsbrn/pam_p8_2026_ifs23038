import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pam_p8_2026_ifs23038/data/services/todo_service.dart';

void main() {
  group('TodoService.getTodos', () {
    test(
      'mengirim query page, perPage, dan search lalu mem-parse response',
      () async {
        late Uri capturedUri;
        late Map<String, String> capturedHeaders;

        final client = MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;

          return http.Response(
            jsonEncode({
              'message': 'OK',
              'data': {
                'todos': [
                  {
                    'id': 'todo-1',
                    'userId': 'user-1',
                    'title': 'Belanja',
                    'description': 'Beli susu',
                    'isDone': false,
                    'urlCover': null,
                    'createdAt': '2026-01-01T00:00:00.000Z',
                    'updatedAt': '2026-01-01T00:00:00.000Z',
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = TodoService(client: client);
        final result = await service.getTodos(
          authToken: 'token-123',
          search: 'bel',
          page: 2,
          perPage: 10,
        );

        expect(result.success, isTrue);
        expect(result.data?.length, 1);
        expect(result.data?.first.id, 'todo-1');

        expect(capturedUri.queryParameters['search'], 'bel');
        expect(capturedUri.queryParameters['page'], '2');
        expect(capturedUri.queryParameters['perPage'], '10');
        expect(capturedHeaders['Authorization'], 'Bearer token-123');
      },
    );

    test('mengembalikan gagal saat status code bukan 200', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );

      final service = TodoService(client: client);
      final result = await service.getTodos(
        authToken: 'invalid-token',
        page: 1,
        perPage: 10,
      );

      expect(result.success, isFalse);
      expect(result.message, 'Unauthorized');
    });
  });
}
