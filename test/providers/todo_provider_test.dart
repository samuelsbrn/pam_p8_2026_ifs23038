import 'package:flutter_test/flutter_test.dart';
import 'package:pam_p8_2026_ifs23038/providers/todo_provider.dart';
import '../helpers/test_fakes.dart';

void main() {
  group('TodoProvider', () {
    test('loadTodosFirstPage memuat 10 data awal dan hasMore true', () async {
      final repository = FakeTodoRepository()
        ..pagedTodosByPage[1] = List.generate(10, (i) => makeTodo(i + 1));
      final provider = TodoProvider(repository: repository);

      await provider.loadTodosFirstPage(authToken: 'token');

      expect(provider.status, TodoStatus.success);
      expect(provider.pagedTodos.length, 10);
      expect(provider.hasMorePagedTodos, isTrue);
      expect(provider.isLoadingMorePagedTodos, isFalse);
      expect(repository.getTodosCalls.first['page'], 1);
      expect(repository.getTodosCalls.first['perPage'], 10);
    });

    test(
      'loadMoreTodos menambahkan halaman berikutnya dan berhenti di halaman akhir',
      () async {
        final repository = FakeTodoRepository()
          ..pagedTodosByPage[1] = List.generate(10, (i) => makeTodo(i + 1))
          ..pagedTodosByPage[2] = List.generate(3, (i) => makeTodo(i + 11));
        final provider = TodoProvider(repository: repository);

        await provider.loadTodosFirstPage(authToken: 'token');
        await provider.loadMoreTodos(authToken: 'token');

        expect(provider.pagedTodos.length, 13);
        expect(provider.hasMorePagedTodos, isFalse);
        expect(provider.pagedTodos.any((t) => t.id == 'todo-11'), isTrue);
        expect(repository.getTodosCalls.map((e) => e['page']).toList(), [1, 2]);
      },
    );

    test('loadMoreTodos mengabaikan data duplikat berdasarkan id', () async {
      final repository = FakeTodoRepository()
        ..pagedTodosByPage[1] = List.generate(10, (i) => makeTodo(i + 1))
        ..pagedTodosByPage[2] = [makeTodo(10), makeTodo(11)];
      final provider = TodoProvider(repository: repository);

      await provider.loadTodosFirstPage(authToken: 'token');
      await provider.loadMoreTodos(authToken: 'token');

      expect(provider.pagedTodos.length, 11);
      expect(provider.pagedTodos.where((t) => t.id == 'todo-10').length, 1);
    });

    test(
      'updateSearchQuery memfilter pagedTodos berdasarkan judul dan deskripsi',
      () async {
        final repository = FakeTodoRepository()
          ..pagedTodosByPage[1] = [
            makeTodo(
              1,
              title: 'Belanja Bulanan',
              description: 'Rencana belanja',
            ),
            makeTodo(2, title: 'Belajar', description: 'Kerja kelompok malam'),
            makeTodo(3, title: 'Olahraga', description: 'Jogging pagi'),
          ];
        final provider = TodoProvider(repository: repository);

        await provider.loadTodosFirstPage(authToken: 'token');
        provider.updateSearchQuery('kelompok');
        expect(provider.pagedTodos.map((e) => e.id), ['todo-2']);

        provider.updateSearchQuery('belanja');
        expect(provider.pagedTodos.map((e) => e.id), ['todo-1']);

        provider.updateSearchQuery('');
        expect(provider.pagedTodos.length, 3);
      },
    );

    test(
      'addTodo me-refresh daftar full dan halaman pertama saat pagination aktif',
      () async {
        final todo1 = makeTodo(1);
        final todo2 = makeTodo(2);
        final repository = FakeTodoRepository();
        repository
          ..allTodos = [todo1]
          ..pagedTodosByPage[1] = [todo1]
          ..onCreateTodo = () async {
            repository.allTodos = [todo1, todo2];
            repository.pagedTodosByPage[1] = [todo1, todo2];
          };
        final provider = TodoProvider(repository: repository);

        await provider.loadTodosFirstPage(authToken: 'token');
        await provider.loadTodos(authToken: 'token');
        final success = await provider.addTodo(
          authToken: 'token',
          title: 'Todo 2',
          description: 'Desc 2',
        );

        expect(success, isTrue);
        expect(provider.status, TodoStatus.success);
        expect(provider.todos.length, 2);
        expect(provider.pagedTodos.length, 2);
      },
    );

    test('editTodo mengubah item pada daftar full dan paged', () async {
      final original = makeTodo(1, isDone: false, title: 'Awal');
      final updated = makeTodo(1, isDone: true, title: 'Diperbarui');

      final repository = FakeTodoRepository()
        ..allTodos = [original]
        ..pagedTodosByPage[1] = [original]
        ..todoByIdMap[original.id] = updated;

      final provider = TodoProvider(repository: repository);
      await provider.loadTodos(authToken: 'token');
      await provider.loadTodosFirstPage(authToken: 'token');

      final success = await provider.editTodo(
        authToken: 'token',
        todoId: original.id,
        title: updated.title,
        description: updated.description,
        isDone: updated.isDone,
      );

      expect(success, isTrue);
      expect(provider.selectedTodo?.title, 'Diperbarui');
      expect(provider.pagedTodos.first.title, 'Diperbarui');
      expect(provider.todos.first.isDone, isTrue);
    });

    test('removeTodo menghapus item dari daftar full dan paged', () async {
      final todo1 = makeTodo(1);
      final todo2 = makeTodo(2);

      final repository = FakeTodoRepository()
        ..allTodos = [todo1, todo2]
        ..pagedTodosByPage[1] = [todo1, todo2];

      final provider = TodoProvider(repository: repository);
      await provider.loadTodos(authToken: 'token');
      await provider.loadTodosFirstPage(authToken: 'token');

      final success = await provider.removeTodo(
        authToken: 'token',
        todoId: todo1.id,
      );

      expect(success, isTrue);
      expect(provider.todos.any((t) => t.id == todo1.id), isFalse);
      expect(provider.pagedTodos.any((t) => t.id == todo1.id), isFalse);
      expect(provider.todos.length, 1);
      expect(provider.pagedTodos.length, 1);
    });
  });
}
