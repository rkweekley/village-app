import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/features/shopping/shopping_service.dart';

class ShoppingListsPage extends ConsumerWidget {
  const ShoppingListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateListDialog(context, ref),
          ),
        ],
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No shopping lists yet. Tap + to create one.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(shoppingListsProvider.future),
            child: ListView.builder(
              itemCount: lists.length,
              itemBuilder: (ctx, i) {
                final list = lists[i];
                final progress =
                    list.itemCount > 0 ? list.checkedCount / list.itemCount : 0.0;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: progress >= 1.0
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Text(
                        '${list.checkedCount}/${list.itemCount}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text(list.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (list.itemCount > 0)
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        const SizedBox(height: 4),
                        Text('${list.itemCount} items',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (action) {
                        if (action == 'delete') {
                          ref
                              .read(shoppingServiceProvider)
                              .deleteList(list.id);
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ShoppingListDetailPage(listId: list.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Shopping List'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'List name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              ref
                  .read(shoppingServiceProvider)
                  .createList(nameCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
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
        title: detailAsync.when(
          data: (detail) => Text(detail.name),
          loading: () => const Text('Loading...'),
          error: (e, _) => const Text('Shopping List'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (detail) {
          if (detail.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_shopping_cart,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('List is empty. Tap + to add items.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final checked = detail.items.where((i) => i.isChecked).toList();
          final unchecked = detail.items.where((i) => !i.isChecked).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(shoppingListDetailProvider(widget.listId).future),
            child: ListView(
              children: [
                if (unchecked.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('To Get (${unchecked.length})',
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  ...unchecked.map((item) => _ItemTile(
                        item: item,
                        listId: widget.listId,
                        ref: ref,
                      )),
                ],
                if (checked.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Checked (${checked.length})',
                        style: Theme.of(context).textTheme.titleSmall),
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

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    String? category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Item name'),
                autofocus: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: category,
                      decoration:
                          const InputDecoration(labelText: 'Category'),
                      items: ['Produce', 'Dairy', 'Meat', 'Bakery', 'Pantry', 'Other']
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => category = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                ref.read(shoppingServiceProvider).addItem(
                      widget.listId,
                      name: nameCtrl.text,
                      quantity: int.tryParse(qtyCtrl.text) ?? 1,
                      category: category,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
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
    return ListTile(
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (_) {
          ref.read(shoppingServiceProvider).toggleItem(listId, item.id);
        },
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration:
              item.isChecked ? TextDecoration.lineThrough : null,
          color: item.isChecked ? Colors.grey : null,
        ),
      ),
      subtitle: item.unit != null
          ? Text('${item.quantity} ${item.unit}')
          : Text('x${item.quantity}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.category != null) ...[
            Chip(
              label: Text(
                item.category!,
                style: const TextStyle(fontSize: 10),
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () {
              ref
                  .read(shoppingServiceProvider)
                  .deleteItem(listId, item.id);
            },
          ),
        ],
      ),
    );
  }
}

final shoppingListDetailProvider =
    FutureProvider.family<ShoppingListDetail, String>((ref, listId) {
  return ref.watch(shoppingServiceProvider).getList(listId);
});
