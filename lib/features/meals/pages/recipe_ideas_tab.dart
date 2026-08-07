import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/meals/recipe_ideas_service.dart';
import 'package:village_app/features/meals/pages/recipe_idea_detail_sheet.dart';
import 'package:village_app/core/widgets/empty_state.dart';

/// Browse recipe ideas from TheMealDB — categories, search, and "Surprise Me".
class RecipeIdeasTab extends ConsumerStatefulWidget {
  const RecipeIdeasTab({super.key});

  @override
  ConsumerState<RecipeIdeasTab> createState() => _RecipeIdeasTabState();
}

class _RecipeIdeasTabState extends ConsumerState<RecipeIdeasTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  String? _selectedCategory;
  String? _searchQuery;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(recipeCategoriesProvider);

    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: VillageTheme.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) {
                    _debounceTimer?.cancel();
                    _debounceTimer =
                        Timer(const Duration(milliseconds: 500), () {
                      final trimmed = v.trim();
                      setState(() {
                        _searchQuery = trimmed.isNotEmpty ? trimmed : null;
                        _selectedCategory = null;
                      });
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Surprise Me
              IconButton.filled(
                onPressed: _getRandomRecipe,
                icon: const Icon(Icons.casino_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: VillageTheme.warning
                      .withValues(alpha: 0.15),
                  foregroundColor: VillageTheme.warning,
                ),
                tooltip: 'Surprise Me',
              ),
            ],
          ),
        ),

        // ── Category chips ──
        categoriesAsync.when(
          data: (categories) => SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (_searchQuery == null ? 1 : 0) + categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                // "All" chip when not searching
                if (_searchQuery == null && i == 0) {
                  return FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                    },
                    showCheckmark: false,
                    selectedColor:
                        VillageTheme.primary.withValues(alpha: 0.15),
                  );
                }
                final cat =
                    categories[_searchQuery == null ? i - 1 : i];
                return FilterChip(
                  label: Text(cat.name),
                  selected: _selectedCategory == cat.name,
                  onSelected: (_) {
                    setState(() {
                      _searchQuery = null;
                      _searchCtrl.clear();
                      _selectedCategory =
                          _selectedCategory == cat.name ? null : cat.name;
                    });
                  },
                  showCheckmark: false,
                  selectedColor:
                      VillageTheme.primary.withValues(alpha: 0.15),
                );
              },
            ),
          ),
          loading: () => const SizedBox(height: 44),
          error: (_, __) => const SizedBox(height: 44),
        ),

        const SizedBox(height: 8),

        // ── Results ──
        Expanded(
          child: _buildResults(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    // Search results
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final resultsAsync = ref.watch(recipeIdeasSearchProvider(_searchQuery!));
      return resultsAsync.when(
        data: (recipes) => _recipeGrid(recipes,
            emptyMessage: 'No recipes found for "$_searchQuery"'),
        loading: () => _loadingGrid(),
        error: (e, _) => _errorWidget(),
      );
    }

    // Category browse
    if (_selectedCategory != null) {
      final resultsAsync =
          ref.watch(recipeIdeasByCategoryProvider(_selectedCategory!));
      return resultsAsync.when(
        data: (recipes) => _recipeGrid(recipes,
            emptyMessage: 'No recipes in $_selectedCategory'),
        loading: () => _loadingGrid(),
        error: (e, _) => _errorWidget(),
      );
    }

    // Default — browse "All" (use popular categories for a landing view)
    return _recipeGrid(const [],
        emptyMessage: 'Search recipes or pick a category above');
  }

  Widget _recipeGrid(List<RecipeIdea> recipes, {String? emptyMessage}) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 48, color: VillageTheme.textTertiary),
              const SizedBox(height: 12),
              Text(emptyMessage ?? 'No recipes yet',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              if (_searchQuery == null && _selectedCategory == null)
                FilledButton.icon(
                  onPressed: _getRandomRecipe,
                  icon: const Icon(Icons.casino_rounded, size: 18),
                  label: const Text('Surprise Me'),
                ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: recipes.length,
      itemBuilder: (ctx, i) => _recipeCard(recipes[i]),
    );
  }

  Widget _recipeCard(RecipeIdea recipe) {
    return GestureDetector(
      onTap: () => _openDetail(recipe),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: VillageTheme.surfaceCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Image.network(
                recipe.image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: VillageTheme.primary.withValues(alpha: 0.12),
                  child: const Center(
                    child: Icon(Icons.restaurant_rounded,
                        size: 32, color: VillageTheme.primary),
                  ),
                ),
              ),
            ),
            // Title
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (recipe.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: VillageTheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe.category!,
                          style: TextStyle(
                            fontSize: 11,
                            color: VillageTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingGrid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: VillageTheme.surfaceCard,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _errorWidget() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: VillageTheme.textTertiary),
              const SizedBox(height: 12),
              const Text("Recipe ideas aren't available right now",
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(recipeCategoriesProvider);
                  if (_selectedCategory != null) {
                    ref.invalidate(recipeIdeasByCategoryProvider(
                        _selectedCategory!));
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  void _openDetail(RecipeIdea recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: VillageTheme.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProviderScope(
        child: RecipeIdeaDetailSheet(recipe: recipe),
      ),
    );
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = null;
    });
  }

  void _getRandomRecipe() async {
    final service = ref.read(recipeIdeasServiceProvider);
    try {
      final recipe = await service.getRandom();
      if (mounted) _openDetail(recipe);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load a random recipe")),
        );
      }
    }
  }
}
