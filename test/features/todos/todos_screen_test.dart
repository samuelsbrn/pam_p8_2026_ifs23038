import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pam_p8_2026_ifs23038/features/todos/todos_screen.dart';
import 'package:pam_p8_2026_ifs23038/providers/auth_provider.dart';
import 'package:pam_p8_2026_ifs23038/providers/theme_provider.dart';
import 'package:pam_p8_2026_ifs23038/providers/todo_provider.dart';
import '../../helpers/test_fakes.dart';

Widget _buildTestApp({required TodoProvider todoProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => StaticAuthProvider(
          token: 'auth-token',
          currentUser: makeUser(name: 'Tester'),
        ),
      ),
      ChangeNotifierProvider<TodoProvider>.value(value: todoProvider),
    ],
    child: const MaterialApp(home: TodosScreen()),
  );
}

void main() {
  testWidgets(
    'TodosScreen memuat halaman awal, infinite scroll, lalu filter selesai',
    (tester) async {
      final repository = FakeTodoRepository()
        ..pagedTodosByPage[1] = List.generate(
          10,
          (i) => makeTodo(i + 1, isDone: (i + 1).isEven),
        )
        ..pagedTodosByPage[2] = List.generate(
          3,
          (i) => makeTodo(i + 11, isDone: (i + 11).isEven),
        );

      final provider = TodoProvider(repository: repository);

      await tester.pumpWidget(_buildTestApp(todoProvider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Todo 1'), findsOneWidget);
      expect(find.text('Todo 11'), findsNothing);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Todo 11'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, 1400));
      await tester.pumpAndSettle();

      final doneChipLabelFinder = find.textContaining('Selesai (');
      expect(doneChipLabelFinder, findsOneWidget);
      await tester.tap(doneChipLabelFinder);
      await tester.pumpAndSettle();

      expect(find.text('Todo 1'), findsNothing);
      expect(find.text('Todo 2'), findsOneWidget);
    },
  );
}
