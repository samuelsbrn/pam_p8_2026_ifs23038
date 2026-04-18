// lib/providers/todo_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../data/models/todo_model.dart';
import '../data/services/todo_repository.dart';

enum TodoStatus { initial, loading, success, error }

class TodoProvider extends ChangeNotifier {
  TodoProvider({TodoRepository? repository})
      : _repository = repository ?? TodoRepository();

  static const int _perPage = 10;

  final TodoRepository _repository;

  TodoStatus _status = TodoStatus.initial;
  List<TodoModel> _todos = [];
  List<TodoModel> _pagedTodos = [];
  TodoModel? _selectedTodo;
  String _errorMessage = '';
  String _searchQuery = '';

  int _currentPage = 0;
  bool _hasMorePagedTodos = true;
  bool _isLoadingMorePagedTodos = false;
  bool _hasInitializedPagedTodos = false;

  TodoStatus get status => _status;
  TodoModel? get selectedTodo => _selectedTodo;
  String get errorMessage => _errorMessage;
  bool get hasMorePagedTodos => _hasMorePagedTodos;
  bool get isLoadingMorePagedTodos => _isLoadingMorePagedTodos;

  List<TodoModel> get todos => _applySearch(_todos);
  List<TodoModel> get pagedTodos => _applySearch(_pagedTodos);

  int get totalTodos => _todos.length;
  int get doneTodos => _todos.where((todo) => todo.isDone).length;
  int get pendingTodos => _todos.where((todo) => !todo.isDone).length;

  List<TodoModel> _applySearch(List<TodoModel> source) {
    if (_searchQuery.trim().isEmpty) {
      return List.unmodifiable(source);
    }
    final keyword = _searchQuery.trim().toLowerCase();
    return source
        .where(
          (todo) =>
              todo.title.toLowerCase().contains(keyword) ||
              todo.description.toLowerCase().contains(keyword),
        )
        .toList();
  }

  Future<void> loadTodos({required String authToken}) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodos(authToken: authToken);
    if (result.success && result.data != null) {
      _todos = result.data!;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  Future<void> loadTodosFirstPage({required String authToken}) async {
    _hasInitializedPagedTodos = true;
    _currentPage = 1;
    _hasMorePagedTodos = true;
    _isLoadingMorePagedTodos = false;
    _pagedTodos = [];

    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodos(
      authToken: authToken,
      page: _currentPage,
      perPage: _perPage,
    );

    if (result.success && result.data != null) {
      _pagedTodos = result.data!;
      _hasMorePagedTodos = result.data!.length == _perPage;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  Future<void> loadMoreTodos({required String authToken}) async {
    if (!_hasInitializedPagedTodos || !_hasMorePagedTodos || _isLoadingMorePagedTodos) {
      return;
    }

    _isLoadingMorePagedTodos = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final result = await _repository.getTodos(
      authToken: authToken,
      page: nextPage,
      perPage: _perPage,
    );

    if (result.success && result.data != null) {
      final incoming = result.data!;
      final existingIds = _pagedTodos.map((todo) => todo.id).toSet();
      final uniqueItems = incoming
          .where((todo) => !existingIds.contains(todo.id))
          .toList();
      _pagedTodos = [..._pagedTodos, ...uniqueItems];
      _currentPage = nextPage;
      _hasMorePagedTodos = incoming.length == _perPage;
    } else {
      _errorMessage = result.message;
      if (_pagedTodos.isEmpty) {
        _status = TodoStatus.error;
      }
    }

    _isLoadingMorePagedTodos = false;
    notifyListeners();
  }

  Future<void> loadTodoById({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.getTodoById(authToken: authToken, todoId: todoId);
    if (result.success && result.data != null) {
      _selectedTodo = result.data;
      _setStatus(TodoStatus.success);
    } else {
      _errorMessage = result.message;
      _setStatus(TodoStatus.error);
    }
  }

  Future<bool> addTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.createTodo(
      authToken: authToken,
      title: title,
      description: description,
    );
    if (result.success) {
      await _refreshAllTodosSnapshot(authToken);
      await _refreshPagedTodosSnapshot(authToken);
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  Future<bool> editTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodo(
      authToken: authToken,
      todoId: todoId,
      title: title,
      description: description,
      isDone: isDone,
    );
    if (result.success) {
      final detailResult = await _repository.getTodoById(
        authToken: authToken,
        todoId: todoId,
      );
      if (detailResult.success && detailResult.data != null) {
        final updatedTodo = detailResult.data!;
        _selectedTodo = updatedTodo;
        _replaceTodoInList(_todos, updatedTodo);
        _replaceTodoInList(_pagedTodos, updatedTodo);
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  Future<bool> updateCover({
    required String authToken,
    required String todoId,
    File? imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.updateTodoCover(
      authToken: authToken,
      todoId: todoId,
      imageFile: imageFile,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
    if (result.success) {
      final detailResult = await _repository.getTodoById(
        authToken: authToken,
        todoId: todoId,
      );
      if (detailResult.success && detailResult.data != null) {
        final updatedTodo = detailResult.data!;
        _selectedTodo = updatedTodo;
        _replaceTodoInList(_todos, updatedTodo);
        _replaceTodoInList(_pagedTodos, updatedTodo);
      }
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  Future<bool> removeTodo({
    required String authToken,
    required String todoId,
  }) async {
    _setStatus(TodoStatus.loading);
    final result = await _repository.deleteTodo(authToken: authToken, todoId: todoId);
    if (result.success) {
      _selectedTodo = null;
      _todos.removeWhere((todo) => todo.id == todoId);
      _pagedTodos.removeWhere((todo) => todo.id == todoId);
      _setStatus(TodoStatus.success);
      return true;
    }
    _errorMessage = result.message;
    _setStatus(TodoStatus.error);
    return false;
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSelectedTodo() {
    _selectedTodo = null;
    notifyListeners();
  }

  Future<void> _refreshAllTodosSnapshot(String authToken) async {
    final listResult = await _repository.getTodos(authToken: authToken);
    if (listResult.success && listResult.data != null) {
      _todos = listResult.data!;
    }
  }

  Future<void> _refreshPagedTodosSnapshot(String authToken) async {
    if (!_hasInitializedPagedTodos) return;

    final pagedResult = await _repository.getTodos(
      authToken: authToken,
      page: 1,
      perPage: _perPage,
    );
    if (pagedResult.success && pagedResult.data != null) {
      _currentPage = 1;
      _pagedTodos = pagedResult.data!;
      _hasMorePagedTodos = pagedResult.data!.length == _perPage;
      _isLoadingMorePagedTodos = false;
    }
  }

  void _replaceTodoInList(List<TodoModel> source, TodoModel todo) {
    final index = source.indexWhere((item) => item.id == todo.id);
    if (index == -1) return;
    source[index] = todo;
  }

  void _setStatus(TodoStatus status) {
    _status = status;
    notifyListeners();
  }
}
