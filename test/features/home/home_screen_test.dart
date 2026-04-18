import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pam_p8_2026_ifs23038/features/home/home_screen.dart';
import 'package:pam_p8_2026_ifs23038/providers/auth_provider.dart';
import 'package:pam_p8_2026_ifs23038/providers/theme_provider.dart';
import 'package:pam_p8_2026_ifs23038/providers/todo_provider.dart';
import '../../helpers/test_fakes.dart';

Widget _buildHomeTestApp({required TodoProvider todoProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => StaticAuthProvider(
          token: 'auth-token',
          currentUser: makeUser(name: 'Adit', username: 'adit'),
        ),
      ),
      ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

void main() {
  testWidgets('HomeScreen menampilkan statistik todo dan progress', (
    tester,
  ) async {
    final repository = FakeTodoRepository()
      ..allTodos = [
        makeTodo(1, isDone: true),
        makeTodo(2, isDone: false),
        makeTodo(3, isDone: false),
        makeTodo(4, isDone: false),
      ];

    final provider = TodoProvider(repository: repository);

    await tester.pumpWidget(_buildHomeTestApp(todoProvider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Belum'), findsOneWidget);

    expect(find.text('(100%)'), findsOneWidget);
    expect(find.text('(25%)'), findsOneWidget);
    expect(find.text('(75%)'), findsOneWidget);

    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });
}
