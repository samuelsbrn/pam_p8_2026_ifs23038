// lib/features/todos/todos_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/route_constants.dart';
import '../../data/models/todo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/top_app_bar_widget.dart';

enum _TodoFilter { all, done, pending }

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final ScrollController _scrollController = ScrollController();
  _TodoFilter _selectedFilter = _TodoFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels < threshold) return;

    final token = context.read<AuthProvider>().authToken;
    if (token == null) return;
    context.read<TodoProvider>().loadMoreTodos(authToken: token);
  }

  Future<void> _loadFirstPage() async {
    final token = context.read<AuthProvider>().authToken;
    if (token == null) return;
    await context.read<TodoProvider>().loadTodosFirstPage(authToken: token);
  }

  List<TodoModel> _applyFilter(List<TodoModel> todos) {
    switch (_selectedFilter) {
      case _TodoFilter.done:
        return todos.where((todo) => todo.isDone).toList();
      case _TodoFilter.pending:
        return todos.where((todo) => !todo.isDone).toList();
      case _TodoFilter.all:
        return todos;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final token = context.read<AuthProvider>().authToken ?? '';

    final pagedTodos = provider.pagedTodos;
    final filteredTodos = _applyFilter(pagedTodos);
    final doneCount = pagedTodos.where((todo) => todo.isDone).length;
    final pendingCount = pagedTodos.where((todo) => !todo.isDone).length;

    final isInitialLoading =
        (provider.status == TodoStatus.loading ||
            provider.status == TodoStatus.initial) &&
        pagedTodos.isEmpty;
    final isInitialError =
        provider.status == TodoStatus.error && pagedTodos.isEmpty;

    return Scaffold(
      appBar: TopAppBarWidget(
        title: 'Todo Saya',
        withSearch: true,
        searchHint: 'Cari todo...',
        onSearchChanged: (query) {
          context.read<TodoProvider>().updateSearchQuery(query);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(RouteConstants.todosAdd).then((_) => _loadFirstPage()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: AppBackground(
        showTopGlow: false,
        child: RefreshIndicator(
          onRefresh: _loadFirstPage,
          child: isInitialLoading
              ? const LoadingWidget(message: 'Memuat todo...')
              : isInitialError
              ? AppErrorWidget(
                  message: provider.errorMessage,
                  onRetry: _loadFirstPage,
                )
              : ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    _TodosHeader(
                      total: pagedTodos.length,
                      done: doneCount,
                      pending: pendingCount,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text('Semua (${pagedTodos.length})'),
                          selected: _selectedFilter == _TodoFilter.all,
                          onSelected: (_) {
                            setState(() => _selectedFilter = _TodoFilter.all);
                          },
                        ),
                        FilterChip(
                          label: Text('Selesai ($doneCount)'),
                          selected: _selectedFilter == _TodoFilter.done,
                          onSelected: (_) {
                            setState(() => _selectedFilter = _TodoFilter.done);
                          },
                        ),
                        FilterChip(
                          label: Text('Belum ($pendingCount)'),
                          selected: _selectedFilter == _TodoFilter.pending,
                          onSelected: (_) {
                            setState(
                              () => _selectedFilter = _TodoFilter.pending,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (filteredTodos.isEmpty)
                      _EmptyTodoState(isNoData: pagedTodos.isEmpty)
                    else ...[
                      for (final todo in filteredTodos) ...[
                        _TodoCard(
                          todo: todo,
                          onTap: () => context
                              .push(RouteConstants.todosDetail(todo.id))
                              .then((_) => _loadFirstPage()),
                          onToggle: () async {
                            final success = await provider.editTodo(
                              authToken: token,
                              todoId: todo.id,
                              title: todo.title,
                              description: todo.description,
                              isDone: !todo.isDone,
                            );
                            if (!context.mounted || success) return;
                            showAppSnackBar(
                              context,
                              message: provider.errorMessage,
                              type: SnackBarType.error,
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                    if (provider.isLoadingMorePagedTodos) ...[
                      const SizedBox(height: 8),
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ] else if (!provider.hasMorePagedTodos &&
                        pagedTodos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Semua data todo sudah dimuat.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _TodosHeader extends StatelessWidget {
  const _TodosHeader({
    required this.total,
    required this.done,
    required this.pending,
  });

  final int total;
  final int done;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      ),
      child: Row(
        children: [
          _InfoBadge(
            icon: Icons.dataset_rounded,
            label: '$total item',
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _InfoBadge(
            icon: Icons.check_circle_rounded,
            label: '$done selesai',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _InfoBadge(
            icon: Icons.pending_rounded,
            label: '$pending belum',
            color: const Color(0xFFFF9F1C),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onTap,
    required this.onToggle,
  });

  final TodoModel todo;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = todo.isDone
        ? const Color(0xFF10B981)
        : const Color(0xFFFF9F1C);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    todo.isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      todo.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: statusColor.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        todo.isDone ? 'Selesai' : 'Belum',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTodoState extends StatelessWidget {
  const _EmptyTodoState({required this.isNoData});

  final bool isNoData;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
              ),
              child: Icon(
                isNoData ? Icons.inbox_outlined : Icons.filter_alt_off_outlined,
                size: 42,
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isNoData
                  ? 'Belum ada todo.\nKetuk + untuk menambahkan.'
                  : 'Tidak ada todo untuk filter ini.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
