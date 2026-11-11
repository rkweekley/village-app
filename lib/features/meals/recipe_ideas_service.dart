import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Parsing helpers ──
//
// The API is the authority on recipe data, but a single unexpected value in
// one record must never take down the whole list. Everything below reads
// defensively and reports what it dropped instead of throwing a cast error.

String _asString(Object? value) {
  if (value is String) return value;
  if (value == null) return '';
  return value.toString();
}

String? _asOptionalString(Object? value) {
  if (value == null) return null;
  final text = _asString(value).trim();
  return text.isEmpty ? null : text;
}

// ── Models ──

class RecipeIdea {
  final String id;
  final String title;
  final String image;
  final String? category;
  final String? area;
  final String instructions;
  final String? youtubeUrl;
  final List<IngredientIdea> ingredients;

  RecipeIdea({
    required this.id,
    required this.title,
    required this.image,
    this.category,
    this.area,
    required this.instructions,
    this.youtubeUrl,
    required this.ingredients,
  });

  bool get hasImage => image.trim().isNotEmpty;

  factory RecipeIdea.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final rawIngredients = json['ingredients'];
    final ingredients = <IngredientIdea>[];
    if (rawIngredients is List) {
      for (final raw in rawIngredients) {
        final ingredient = IngredientIdea.tryParse(raw);
        if (ingredient != null) ingredients.add(ingredient);
      }
    }

    final id = _asString(json['id']).trim();

    return RecipeIdea(
      id: id.isNotEmpty ? id : (fallbackId ?? ''),
      title: _asString(json['title']).trim(),
      image: _asString(json['image']).trim(),
      category: _asOptionalString(json['category']),
      area: _asOptionalString(json['area']),
      instructions: _asString(json['instructions']),
      youtubeUrl: _asOptionalString(json['youtubeUrl']),
      ingredients: ingredients,
    );
  }
}

class IngredientIdea {
  final String name;
  final String measure;

  IngredientIdea({required this.name, required this.measure});

  /// Returns null for entries that carry no usable name, so one malformed
  /// ingredient drops a row instead of failing the recipe.
  static IngredientIdea? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final name = _asString(raw['name']).trim();
    if (name.isEmpty) return null;
    return IngredientIdea(
      name: name,
      measure: _asString(raw['measure']).trim(),
    );
  }

  factory IngredientIdea.fromJson(Map<String, dynamic> json) => IngredientIdea(
    name: _asString(json['name']).trim(),
    measure: _asString(json['measure']).trim(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'measure': measure.isNotEmpty ? measure : null,
  };
}

class CategoryInfo {
  final String id;
  final String name;
  final String thumb;
  final String description;

  CategoryInfo({
    required this.id,
    required this.name,
    required this.thumb,
    required this.description,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) => CategoryInfo(
    id: _asString(json['id']).trim(),
    name: _asString(json['name']).trim(),
    thumb: _asString(json['thumb']).trim(),
    description: _asString(json['description']).trim(),
  );
}

// ── Service ──

class RecipeIdeasService {
  final Dio _dio;

  RecipeIdeasService(this._dio);

  Future<List<RecipeIdea>> search(String query) async {
    final response = await _dio.get(
      '/api/recipes/ideas/search',
      queryParameters: {'q': query},
    );
    return _parseRecipes(response.data, 'search');
  }

  Future<List<RecipeIdea>> byCategory(String category) async {
    final response = await _dio.get('/api/recipes/ideas/category/$category');
    return _parseRecipes(response.data, 'category/$category', summary: true);
  }

  Future<RecipeIdea> getDetail(String id) async {
    final response = await _dio.get('/api/recipes/ideas/$id');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected recipe detail payload (${data.runtimeType})',
      );
    }
    return RecipeIdea.fromJson(data, fallbackId: id);
  }

  Future<RecipeIdea> getRandom() async {
    final response = await _dio.get('/api/recipes/ideas/random');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Unexpected random recipe payload (${data.runtimeType})',
      );
    }
    return RecipeIdea.fromJson(data);
  }

  Future<List<CategoryInfo>> getCategories() async {
    final response = await _dio.get('/api/recipes/ideas/categories');
    final data = response.data;
    if (data is! List) {
      debugPrint(
        '[RecipeIdeas] categories: expected a list, got ${data.runtimeType}',
      );
      return const [];
    }
    final categories = <CategoryInfo>[];
    for (final raw in data) {
      if (raw is! Map<String, dynamic>) {
        debugPrint(
          '[RecipeIdeas] categories: skipped non-object entry '
          '(${raw.runtimeType})',
        );
        continue;
      }
      final category = CategoryInfo.fromJson(raw);
      if (category.id.isEmpty) {
        debugPrint('[RecipeIdeas] categories: skipped entry with no id');
        continue;
      }
      categories.add(category);
    }
    return categories;
  }

  /// Map a list payload, skipping (and reporting) individual bad records.
  ///
  /// Previously this was `.map((j) => RecipeIdea.fromJson(j as Map<String,
  /// dynamic>))`, so a null image or a numeric id threw a type error and the
  /// entire result — not just the bad record — failed to load (#109).
  List<RecipeIdea> _parseRecipes(
    Object? data,
    String source, {
    bool summary = false,
  }) {
    if (data is! List) {
      debugPrint(
        '[RecipeIdeas] $source: expected a list, got ${data.runtimeType}',
      );
      return <RecipeIdea>[];
    }

    final recipes = <RecipeIdea>[];
    for (final raw in data) {
      if (raw is! Map<String, dynamic>) {
        debugPrint(
          '[RecipeIdeas] $source: skipped non-object entry '
          '(${raw.runtimeType})',
        );
        continue;
      }
      try {
        final recipe = summary
            ? _fromSummaryJson(raw)
            : RecipeIdea.fromJson(raw);
        // Without an id there is nothing to fetch for the detail sheet, so the
        // tile could never open — drop it rather than render a dead card.
        if (recipe.id.isEmpty) {
          debugPrint(
            '[RecipeIdeas] $source: skipped entry with no id '
            '("${recipe.title}")',
          );
          continue;
        }
        recipes.add(recipe);
      } catch (error) {
        debugPrint('[RecipeIdeas] $source: skipped malformed entry — $error');
      }
    }
    return recipes;
  }

  /// Category-filter results are summaries — no ingredient detail yet.
  RecipeIdea _fromSummaryJson(Map<String, dynamic> json) => RecipeIdea(
    id: _asString(json['id']).trim(),
    title: _asString(json['title']).trim(),
    image: _asString(json['image']).trim(),
    instructions: '',
    ingredients: [],
  );
}

// ── Providers ──

final recipeIdeasServiceProvider = Provider<RecipeIdeasService>((ref) {
  return RecipeIdeasService(ref.read(authenticatedDioProvider));
});

final recipeCategoriesProvider = FutureProvider<List<CategoryInfo>>((ref) {
  return ref.read(recipeIdeasServiceProvider).getCategories();
});

final recipeIdeasByCategoryProvider =
    FutureProvider.family<List<RecipeIdea>, String>((ref, category) {
      return ref.read(recipeIdeasServiceProvider).byCategory(category);
    });

final recipeIdeasSearchProvider =
    FutureProvider.family<List<RecipeIdea>, String>((ref, query) {
      return ref.read(recipeIdeasServiceProvider).search(query);
    });

final recipeIdeaDetailProvider = FutureProvider.family<RecipeIdea, String>((
  ref,
  id,
) {
  return ref.read(recipeIdeasServiceProvider).getDetail(id);
});
