import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/core/widgets/empty_state.dart';
import 'package:village_app/features/shopping/shopping_service.dart';
import 'package:village_app/core/auth/auth_provider.dart';
import 'package:village_app/shared/widgets/adaptive_sheet.dart';

class ShoppingListsPage extends ConsumerWidget {
  const ShoppingListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider);
    final isParent = ref.watch(authProvider).canManage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        centerTitle: true,
      ),
      floatingActionButton: isParent
          ? FloatingActionButton(
              onPressed: () => _showCreateListSheet(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lists) {
          if (lists.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_rounded,
              title: 'No shopping lists yet',
              subtitle: 'Tap + to create one',
              iconBgColor: VillageTheme.primary,
              iconColor: VillageTheme.primary,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(shoppingListsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: lists.length,
              itemBuilder: (ctx, i) {
                final list = lists[i];
                final progress =
                    list.itemCount > 0 ? list.checkedCount / list.itemCount : 0.0;
                final isComplete = progress >= 1.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  color: VillageTheme.surfaceCard,
                  child: InkWell(
                    onTap: () => context.push('/shopping-detail/${list.id}'),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Circular progress indicator
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4,
                                    backgroundColor:
                                        VillageTheme.primary
                                            .withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isComplete
                                          ? VillageTheme.positive
                                          : VillageTheme.primary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${list.checkedCount}/${list.itemCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isComplete
                                        ? VillageTheme.positive
                                        : VillageTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // List info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${list.itemCount} items${isComplete ? ' · Done! 🎉' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isComplete
                                        ? VillageTheme.positive
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delete button
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded,
                                color: Colors.grey[400], size: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: VillageTheme.danger,
                                          size: 20),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  )),
                            ],
                            onSelected: (action) {
                              if (action == 'delete') {
                                ref
                                    .read(shoppingServiceProvider)
                                    .deleteList(list.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateListSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VillageTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shopping_cart_rounded,
                      color: VillageTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Shopping List',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'List name',
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                fillColor: VillageTheme.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  await ref.read(shoppingServiceProvider).createList(value.trim());
                  ref.invalidate(shoppingListsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await ref
                      .read(shoppingServiceProvider)
                      .createList(nameCtrl.text.trim());
                  ref.invalidate(shoppingListsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: VillageTheme.primary,
              ),
              child: const Text('Create List',
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class ShoppingListDetailPage extends ConsumerStatefulWidget {
  final String listId;
  const ShoppingListDetailPage({super.key, required this.listId});

  @override
  ConsumerState<ShoppingListDetailPage> createState() =>
      _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState
    extends ConsumerState<ShoppingListDetailPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      shoppingListDetailProvider(widget.listId),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: detailAsync.when(
          data: (detail) => Text(detail.name),
          loading: () => const Text('Loading...'),
          error: (e, _) => const Text('Shopping List'),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail.items.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'List is empty',
              subtitle: 'Tap the FAB to add items',
              iconBgColor: VillageTheme.primary,
              iconColor: VillageTheme.primary,
            );
          }

          final checked = detail.items.where((i) => i.isChecked).toList();
          final unchecked = detail.items.where((i) => !i.isChecked).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(shoppingListDetailProvider(widget.listId).future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Progress header
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  color: VillageTheme.surfaceCard,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: detail.itemCount > 0
                                    ? detail.checkedCount / detail.itemCount
                                    : 0.0,
                                strokeWidth: 4,
                                backgroundColor:
                                    VillageTheme.primary
                                        .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  VillageTheme.primary,
                                ),
                              ),
                              Text(
                                '${detail.checkedCount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: VillageTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Progress',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${detail.checkedCount} of ${detail.itemCount} items checked',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Unchecked items
                if (unchecked.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('To Get (${unchecked.length})',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                  ),
                  ...unchecked.map((item) => _ItemTile(
                        item: item,
                        listId: widget.listId,
                        ref: ref,
                      )),
                  if (checked.isNotEmpty) const SizedBox(height: 16),
                ],

                // Checked items
                if (checked.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Checked (${checked.length})',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey)),
                  ),
                  ...checked.map((item) => _ItemTile(
                        item: item,
                        listId: widget.listId,
                        ref: ref,
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    String? category;

    showAdaptiveModalSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            VillageTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded,
                          color: VillageTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Item',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Item name',
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    filled: true,
                    fillColor: VillageTheme.surfaceBase,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: const Icon(Icons.numbers_outlined),
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: VillageTheme.surfaceBase,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          'Produce',
                          'Dairy',
                          'Meat',
                          'Bakery',
                          'Pantry',
                          'Other'
                        ]
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => category = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      await ref.read(shoppingServiceProvider).addItem(
                            widget.listId,
                            name: nameCtrl.text.trim(),
                            quantity: int.tryParse(qtyCtrl.text) ?? 1,
                            category: category,
                          );
                      ref.invalidate(shoppingListDetailProvider(widget.listId));
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: VillageTheme.primary,
                  ),
                  child: const Text('Add to List',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ShoppingItem item;
  final String listId;
  final WidgetRef ref;

  const _ItemTile({
    required this.item,
    required this.listId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      color: VillageTheme.surfaceCard,
      child: ListTile(
        leading: Checkbox(
          value: item.isChecked,
          activeColor: VillageTheme.positive,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          onChanged: (_) {
            ref.read(shoppingServiceProvider).toggleItem(listId, item.id);
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? Colors.grey : null,
            fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: item.unit != null
            ? Text('${item.quantity} ${item.unit}')
            : Text('x${item.quantity}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _categoryColor(item.category!)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _categoryColor(item.category!),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: VillageTheme.danger.withValues(alpha: 0.7),
              onPressed: () {
                ref
                    .read(shoppingServiceProvider)
                    .deleteItem(listId, item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Produce':
        return VillageTheme.positive;
      case 'Dairy':
        return VillageTheme.info;
      case 'Meat':
        return VillageTheme.danger;
      case 'Bakery':
        return VillageTheme.warning;
      case 'Pantry':
        return VillageTheme.primary;
      default:
        return Colors.grey;
    }
  }
}

final shoppingListDetailProvider =
    FutureProvider.family<ShoppingListDetail, String>((ref, listId) {
  return ref.watch(shoppingServiceProvider).getList(listId);
});
