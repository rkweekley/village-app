import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/theme/village_theme.dart';
import 'package:village_app/features/meals/recipe_ideas_service.dart';
import 'package:village_app/features/meals/pages/recipe_idea_detail_sheet.dart';
import 'package:village_app/features/meals/widgets/recipe_image.dart';

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
                    fillColor: context.palette.surfaceCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) {
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(
                      const Duration(milliseconds: 500),
                      () {
                        final trimmed = v.trim();
                        setState(() {
                          _searchQuery = trimmed.isNotEmpty ? trimmed : null;
                          _selectedCategory = null;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Surprise Me
              IconButton.filled(
                onPressed: _getRandomRecipe,
                icon: const Icon(Icons.casino_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: VillageTheme.warning.withValues(alpha: 0.15),
                  foregroundColor: context.palette.warning,
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
                    selectedColor: context.palette.primary.withValues(
                      alpha: 0.15,
                    ),
                  );
                }
                final cat = categories[_searchQuery == null ? i - 1 : i];
                return FilterChip(
                  label: Text(cat.name),
                  selected: _selectedCategory == cat.name,
                  onSelected: (_) {
                    setState(() {
                      _searchQuery = null;
                      _searchCtrl.clear();
                      _selectedCategory = _selectedCategory == cat.name
                          ? null
                          : cat.name;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: context.palette.primary.withValues(
                    alpha: 0.15,
                  ),
                );
              },
            ),
          ),
          loading: () => const SizedBox(height: 44),
          error: (_, __) => const SizedBox(height: 44),
        ),

        const SizedBox(height: 8),

        // ── Results ──
        Expanded(child: _buildResults()),
      ],
    );
  }

  Widget _buildResults() {
    // Search results
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final resultsAsync = ref.watch(recipeIdeasSearchProvider(_searchQuery!));
      return resultsAsync.when(
        data: (recipes) => _recipeGrid(
          recipes,
          emptyMessage: 'No recipes found for "$_searchQuery"',
        ),
        loading: () => _loadingGrid(),
        error: (e, _) => _errorWidget(),
      );
    }

    // Category browse
    if (_selectedCategory != null) {
      final resultsAsync = ref.watch(
        recipeIdeasByCategoryProvider(_selectedCategory!),
      );
      return resultsAsync.when(
        data: (recipes) => _recipeGrid(
          recipes,
          emptyMessage: 'No recipes in $_selectedCategory',
        ),
        loading: () => _loadingGrid(),
        error: (e, _) => _errorWidget(),
      );
    }

    // Default — browse "All" (use popular categories for a landing view)
    return _recipeGrid(
      const [],
      emptyMessage: 'Search recipes or pick a category above',
    );
  }

  Widget _recipeGrid(List<RecipeIdea> recipes, {String? emptyMessage}) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 48,
                color: context.palette.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage ?? 'No recipes yet',
                style: const TextStyle(fontSize: 16),
              ),
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
        color: context.palette.surfaceCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: RecipeImage(
                url: recipe.image,
                width: double.infinity,
                cacheWidth: 400,
                iconSize: 32,
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
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.palette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          recipe.category!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.palette.primary,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: context.palette.surfaceCard,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );

  Widget _errorWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: context.palette.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            "Recipe ideas aren't available right now",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.invalidate(recipeCategoriesProvider);
              if (_selectedCategory != null) {
                ref.invalidate(
                  recipeIdeasByCategoryProvider(_selectedCategory!),
                );
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  /// Fetch the full recipe, then show it.
  ///
  /// The loading sheet is pushed as an explicit [ModalBottomSheetRoute] so the
  /// exact route can be removed once the fetch finishes. The previous code
  /// called `Navigator.pop(context)` to dismiss it, which pops whatever route
  /// happens to be on top — if the detail sheet had already been pushed the
  /// pop took *that* away and left a blank screen (#105).
  Future<void> _openDetail(RecipeIdea recipe) async {
    final navigator = Navigator.of(context);
    final loadingRoute = ModalBottomSheetRoute<void>(
      builder: (_) => const _LoadingSheet(),
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
    );
    unawaited(navigator.push(loadingRoute));

    final service = ref.read(recipeIdeasServiceProvider);

    try {
      // Category results are summaries without ingredients/instructions, so
      // the detail endpoint is required here.
      final fullRecipe = await service.getDetail(recipe.id);
      if (!mounted) return;
      _closeIfActive(navigator, loadingRoute);
      _showDetailSheet(fullRecipe);
    } on DioException catch (error) {
      if (!mounted) return;
      _closeIfActive(navigator, loadingRoute);
      debugPrint(
        '[RecipeIdeas] detail ${recipe.id} failed: '
        '${error.response?.statusCode ?? error.type} — ${error.message}',
      );
      _showLoadError(
        "Couldn't load recipe details",
        retry: () => _openDetail(recipe),
      );
    } catch (error, stack) {
      if (!mounted) return;
      _closeIfActive(navigator, loadingRoute);
      debugPrint('[RecipeIdeas] detail ${recipe.id} failed: $error\n$stack');
      _showLoadError(
        "Couldn't load recipe details",
        retry: () => _openDetail(recipe),
      );
    }
  }

  void _closeIfActive(
    NavigatorState navigator,
    ModalBottomSheetRoute<void> route,
  ) {
    if (route.isActive) navigator.removeRoute(route);
  }

  void _showLoadError(String message, {VoidCallback? retry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: retry == null
            ? null
            : SnackBarAction(label: 'Retry', onPressed: retry),
      ),
    );
  }

  /// Show an already-complete recipe.
  ///
  /// Deliberately *not* wrapped in a nested `ProviderScope`: a second scope
  /// gave the sheet its own container, so its reads and invalidations never
  /// touched the root providers the rest of the app relies on — and, before
  /// the authenticated client attached its interceptor per instance, every
  /// request made from inside that scope went out unauthenticated (#103, #104).
  void _showDetailSheet(RecipeIdea recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surfaceBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecipeIdeaDetailSheet(recipe: recipe),
    );
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = null;
    });
  }

  /// Surprise Me.
  ///
  /// `getRandom()` already returns a full recipe, so it goes straight to the
  /// detail sheet. Routing it back through `_openDetail()` performed a second
  /// network round trip and could open a *different* recipe than the one the
  /// user was shown (#106).
  Future<void> _getRandomRecipe() async {
    final service = ref.read(recipeIdeasServiceProvider);
    try {
      final recipe = await service.getRandom();
      if (!mounted) return;
      _showDetailSheet(recipe);
    } on DioException catch (error) {
      debugPrint(
        '[RecipeIdeas] random failed: '
        '${error.response?.statusCode ?? error.type} — ${error.message}',
      );
      if (!mounted) return;
      _showLoadError("Couldn't load a random recipe", retry: _getRandomRecipe);
    } catch (error, stack) {
      debugPrint('[RecipeIdeas] random failed: $error\n$stack');
      if (!mounted) return;
      _showLoadError("Couldn't load a random recipe", retry: _getRandomRecipe);
    }
  }
}

/// Simple loading placeholder shown while fetching recipe detail.
class _LoadingSheet extends StatelessWidget {
  const _LoadingSheet();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
