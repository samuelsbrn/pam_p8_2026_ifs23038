import 'dart:typed_data';
import 'package:pam_p8_2026_ifs23038/data/models/api_response_model.dart';
import 'package:pam_p8_2026_ifs23038/data/models/todo_model.dart';
import 'package:pam_p8_2026_ifs23038/data/models/user_model.dart';
import 'package:pam_p8_2026_ifs23038/data/services/auth_repository.dart';
import 'package:pam_p8_2026_ifs23038/data/services/todo_repository.dart';
import 'package:pam_p8_2026_ifs23038/providers/auth_provider.dart';

TodoModel makeTodo(
  int index, {
  bool isDone = false,
  String? title,
  String? description,
}) {
  return TodoModel(
    id: 'todo-$index',
    userId: 'user-1',
    title: title ?? 'Todo $index',
    description: description ?? 'Description $index',
    isDone: isDone,
    urlCover: null,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );
}

UserModel makeUser({
  String id = 'user-1',
  String name = 'Tester',
  String username = 'tester',
  String? urlPhoto,
}) {
  return UserModel(
    id: id,
    name: name,
    username: username,
    urlPhoto: urlPhoto,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
  );
}

class FakeTodoRepository extends TodoRepository {
  FakeTodoRepository();

  List<TodoModel> allTodos = [];
  final Map<int, List<TodoModel>> pagedTodosByPage = {};
  final Map<String, TodoModel> todoByIdMap = {};

  bool shouldFailGetTodos = false;
  bool createTodoSuccess = true;
  bool updateTodoSuccess = true;
  bool updateTodoCoverSuccess = true;
  bool deleteTodoSuccess = true;

  int getTodosCallCount = 0;
  final List<Map<String, int?>> getTodosCalls = [];

  Future<void> Function()? onCreateTodo;
  Future<void> Function()? onUpdateTodo;
  Future<void> Function()? onDeleteTodo;

  @override
  Future<ApiResponse<List<TodoModel>>> getTodos({
    required String authToken,
    String search = '',
    int? page,
    int? perPage,
  }) async {
    getTodosCallCount++;
    getTodosCalls.add({'page': page, 'perPage': perPage});

    if (shouldFailGetTodos) {
      return const ApiResponse(success: false, message: 'Gagal memuat todos.');
    }

    final result = page == null
        ? allTodos
        : (pagedTodosByPage[page] ?? const []);
    return ApiResponse(
      success: true,
      message: 'OK',
      data: List<TodoModel>.from(result),
    );
  }

  @override
  Future<ApiResponse<String>> createTodo({
    required String authToken,
    required String title,
    required String description,
  }) async {
    if (!createTodoSuccess) {
      return const ApiResponse(success: false, message: 'Gagal membuat todo.');
    }
    if (onCreateTodo != null) {
      await onCreateTodo!();
    }
    return const ApiResponse(success: true, message: 'OK', data: 'new-id');
  }

  @override
  Future<ApiResponse<TodoModel>> getTodoById({
    required String authToken,
    required String todoId,
  }) async {
    final todo =
        todoByIdMap[todoId] ??
        allTodos.cast<TodoModel?>().firstWhere(
          (item) => item?.id == todoId,
          orElse: () => null,
        );

    if (todo == null) {
      return const ApiResponse(
        success: false,
        message: 'Todo tidak ditemukan.',
      );
    }

    return ApiResponse(success: true, message: 'OK', data: todo);
  }

  @override
  Future<ApiResponse<void>> updateTodo({
    required String authToken,
    required String todoId,
    required String title,
    required String description,
    required bool isDone,
  }) async {
    if (!updateTodoSuccess) {
      return const ApiResponse(success: false, message: 'Gagal mengubah todo.');
    }
    if (onUpdateTodo != null) {
      await onUpdateTodo!();
    }
    return const ApiResponse(success: true, message: 'OK');
  }

  @override
  Future<ApiResponse<void>> updateTodoCover({
    required String authToken,
    required String todoId,
    imageFile,
    Uint8List? imageBytes,
    String imageFilename = 'cover.jpg',
  }) async {
    if (!updateTodoCoverSuccess) {
      return const ApiResponse(success: false, message: 'Gagal upload cover.');
    }
    if (onUpdateTodo != null) {
      await onUpdateTodo!();
    }
    return const ApiResponse(success: true, message: 'OK');
  }

  @override
  Future<ApiResponse<void>> deleteTodo({
    required String authToken,
    required String todoId,
  }) async {
    if (!deleteTodoSuccess) {
      return const ApiResponse(
        success: false,
        message: 'Gagal menghapus todo.',
      );
    }
    if (onDeleteTodo != null) {
      await onDeleteTodo!();
    }
    return const ApiResponse(success: true, message: 'OK');
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository();

  ApiResponse<String> registerResponse = const ApiResponse(
    success: true,
    message: 'OK',
    data: 'user-1',
  );
  ApiResponse<Map<String, String>> loginResponse = const ApiResponse(
    success: true,
    message: 'OK',
    data: {'authToken': 'auth-token', 'refreshToken': 'refresh-token'},
  );
  ApiResponse<Map<String, String>> refreshTokenResponse = const ApiResponse(
    success: true,
    message: 'OK',
    data: {'authToken': 'new-auth-token', 'refreshToken': 'new-refresh-token'},
  );
  ApiResponse<UserModel> getMeDefaultResponse = const ApiResponse(
    success: false,
    message: 'Profil tidak tersedia.',
  );
  final List<ApiResponse<UserModel>> getMeQueue = [];
  ApiResponse<void> updateMeResponse = const ApiResponse(
    success: true,
    message: 'OK',
  );
  ApiResponse<void> updatePasswordResponse = const ApiResponse(
    success: true,
    message: 'OK',
  );
  ApiResponse<void> updatePhotoResponse = const ApiResponse(
    success: true,
    message: 'OK',
  );
  ApiResponse<void> logoutResponse = const ApiResponse(
    success: true,
    message: 'OK',
  );

  String? lastLoginUsername;
  String? lastLoginPassword;
  String? lastGetMeAuthToken;
  String? lastUpdateName;
  String? lastUpdateUsername;
  String? lastCurrentPassword;
  String? lastNewPassword;
  Uint8List? lastUpdatePhotoBytes;
  String? lastUpdatePhotoFilename;

  @override
  Future<ApiResponse<String>> register({
    required String name,
    required String username,
    required String password,
  }) async {
    return registerResponse;
  }

  @override
  Future<ApiResponse<Map<String, String>>> login({
    required String username,
    required String password,
  }) async {
    lastLoginUsername = username;
    lastLoginPassword = password;
    return loginResponse;
  }

  @override
  Future<ApiResponse<void>> logout({required String authToken}) async {
    return logoutResponse;
  }

  @override
  Future<ApiResponse<Map<String, String>>> refreshToken({
    required String authToken,
    required String refreshToken,
  }) async {
    return refreshTokenResponse;
  }

  @override
  Future<ApiResponse<UserModel>> getMe({required String authToken}) async {
    lastGetMeAuthToken = authToken;
    if (getMeQueue.isNotEmpty) {
      return getMeQueue.removeAt(0);
    }
    return getMeDefaultResponse;
  }

  @override
  Future<ApiResponse<void>> updateMe({
    required String authToken,
    required String name,
    required String username,
  }) async {
    lastUpdateName = name;
    lastUpdateUsername = username;
    return updateMeResponse;
  }

  @override
  Future<ApiResponse<void>> updatePassword({
    required String authToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return updatePasswordResponse;
  }

  @override
  Future<ApiResponse<void>> updatePhoto({
    required String authToken,
    required Uint8List imageBytes,
    String imageFilename = 'photo.jpg',
  }) async {
    lastUpdatePhotoBytes = imageBytes;
    lastUpdatePhotoFilename = imageFilename;
    return updatePhotoResponse;
  }
}

class StaticAuthProvider extends AuthProvider {
  StaticAuthProvider({
    required this.token,
    this.currentUser,
    this.currentStatus = AuthStatus.authenticated,
  }) : super(repository: FakeAuthRepository());

  final String token;
  final UserModel? currentUser;
  final AuthStatus currentStatus;

  @override
  String? get authToken => token;

  @override
  UserModel? get user => currentUser;

  @override
  AuthStatus get status => currentStatus;

  @override
  bool get isAuthenticated => true;
}
