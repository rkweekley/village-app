import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

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

  factory RecipeIdea.fromJson(Map<String, dynamic> json) => RecipeIdea(
        id: json['id'] as String,
        title: json['title'] as String,
        image: json['image'] as String,
        category: json['category'] as String?,
        area: json['area'] as String?,
        instructions: json['instructions'] as String? ?? '',
        youtubeUrl: json['youtubeUrl'] as String?,
        ingredients: (json['ingredients'] as List<dynamic>?)
                ?.map((i) => IngredientIdea.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class IngredientIdea {
  final String name;
  final String measure;

  IngredientIdea({required this.name, required this.measure});

  factory IngredientIdea.fromJson(Map<String, dynamic> json) =>
      IngredientIdea(
        name: json['name'] as String,
        measure: (json['measure'] as String?) ?? '',
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
        id: json['id'] as String,
        name: json['name'] as String,
        thumb: json['thumb'] as String,
        description: json['description'] as String? ?? '',
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
    return (response.data as List<dynamic>)
        .map((j) => RecipeIdea.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecipeIdea>> byCategory(String category) async {
    final response =
        await _dio.get('/api/recipes/ideas/category/$category');
    return (response.data as List<dynamic>)
        .map((j) => _fromSummaryJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeIdea> getDetail(String id) async {
    final response = await _dio.get('/api/recipes/ideas/$id');
    return RecipeIdea.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipeIdea> getRandom() async {
    final response = await _dio.get('/api/recipes/ideas/random');
    return RecipeIdea.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CategoryInfo>> getCategories() async {
    final response = await _dio.get('/api/recipes/ideas/categories');
    return (response.data as List<dynamic>)
        .map((j) => CategoryInfo.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Category-filter results are summaries — no ingredient detail yet.
  RecipeIdea _fromSummaryJson(Map<String, dynamic> json) => RecipeIdea(
        id: json['id'] as String,
        title: json['title'] as String,
        image: json['image'] as String,
        instructions: '',
        ingredients: [],
      );
}

// ── Providers ──

final recipeIdeasServiceProvider = Provider<RecipeIdeasService>((ref) {
  return RecipeIdeasService(ref.read(authenticatedDioProvider));
});

final recipeCategoriesProvider =
    FutureProvider<List<CategoryInfo>>((ref) {
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

final recipeIdeaDetailProvider =
    FutureProvider.family<RecipeIdea, String>((ref, id) {
  return ref.read(recipeIdeasServiceProvider).getDetail(id);
});
