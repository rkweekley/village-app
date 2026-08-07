import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:village_app/core/network/authenticated_client.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/meals/recipe_ideas_service.dart';
import 'package:village_app/features/shopping/shopping_service.dart';

/// Modal bottom sheet showing a recipe from TheMealDB with ingredients
/// and an "Add to Shopping List" flow.
class RecipeIdeaDetailSheet extends ConsumerStatefulWidget {
  final RecipeIdea recipe;

  const RecipeIdeaDetailSheet({required this.recipe, super.key});

  @override
  ConsumerState<RecipeIdeaDetailSheet> createState() =>
      _RecipeIdeaDetailSheetState();
}

class _RecipeIdeaDetailSheetState
    extends ConsumerState<RecipeIdeaDetailSheet> {
  bool _addingToShoppingList = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Stack(
        children: [
          ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // ── Hero image ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: Image.network(
                      recipe.image,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: VillageTheme.primary.withValues(alpha: 0.15),
                        child: const Center(
                          child: Icon(Icons.restaurant_rounded,
                              size: 48, color: VillageTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor:
                          Colors.black.withValues(alpha: 0.35),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Title
                  Positioned(
                    bottom: 12,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          style:
                              theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (recipe.category != null ||
                            recipe.area != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (recipe.category != null)
                                _badge(recipe.category!,
                                    VillageTheme.primary),
                              if (recipe.area != null) ...[
                                const SizedBox(width: 6),
                                _badge(recipe.area!,
                                    VillageTheme.warning),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // ── Actions bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (recipe.youtubeUrl != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(
                              Uri.parse(recipe.youtubeUrl!)),
                          icon: const Icon(Icons.play_circle_outline,
                              size: 18),
                          label:
                              const Text('Watch', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    if (recipe.youtubeUrl != null)
                      const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addingToShoppingList
                            ? null
                            : _showShoppingListPicker,
                        icon: _addingToShoppingList
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.shopping_cart,
                                size: 18),
                        label: Text(
                            _addingToShoppingList
                                ? 'Adding...'
                                : 'Add to List',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Ingredients header ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text('Ingredients',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),

              // ── Ingredient list ──
              ...recipe.ingredients
                  .where((i) => i.name.isNotEmpty)
                  .map((ing) => ListTile(
                        dense: true,
                        leading: Icon(Icons.circle,
                            size: 8,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.5)),
                        title: Text(ing.name,
                            style: const TextStyle(fontSize: 14)),
                        trailing: ing.measure.isNotEmpty
                            ? Text(ing.measure,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600]))
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        visualDensity: VisualDensity.compact,
                      )),

              const SizedBox(height: 8),

              // ── Instructions ──
              if (recipe.instructions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Text('Instructions',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Text(
                    recipe.instructions,
                    style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.grey[800]),
                  ),
                ),
              ],

              const SizedBox(height: 100), // space for FAB
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  void _showShoppingListPicker() {
    final listsAsync = ref.read(shoppingListsProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 48, color: VillageTheme.textTertiary),
                  const SizedBox(height: 12),
                  const Text('No shopping lists yet',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Create one in the Shopping tab first.',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add ingredients to:',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ...lists.map((list) => ListTile(
                      leading: const Icon(Icons.shopping_cart_outlined),
                      title: Text(list.name),
                      subtitle:
                          Text('${list.itemCount} items'),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _addToShoppingList(list.id);
                      },
                    )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _addToShoppingList(String listId) async {
    setState(() => _addingToShoppingList = true);

    try {
      final dio = ref.read(authenticatedDioProvider);
      await dio.post(
        '/api/shopping/$listId/items/bulk',
        data: {
          'ingredients': widget.recipe.ingredients
              .where((i) => i.name.isNotEmpty)
              .map((i) => i.toJson())
              .toList(),
        },
      );
      ref.invalidate(shoppingListsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.recipe.ingredients.where((i) => i.name.isNotEmpty).length} ingredients added'),
            backgroundColor: VillageTheme.positive,
          ),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add ingredients. Check your connection.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToShoppingList = false);
    }
  }
}
