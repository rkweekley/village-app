import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class Recipe {
  final String id;
  final String title;
  final String? description;
  final String ingredients;
  final String instructions;
  final int prepTimeMinutes;
  final int servings;
  final String difficulty;
  final String? tags;
  final String? photoUrl;
  final bool isFamilyFavorite;
  final String createdById;
  final String createdAt;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    this.servings = 4,
    required this.difficulty,
    this.tags,
    this.photoUrl,
    this.isFamilyFavorite = false,
    required this.createdById,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        ingredients: json['ingredients'] as String,
        instructions: json['instructions'] as String,
        prepTimeMinutes: json['prepTimeMinutes'] as int,
        servings: json['servings'] as int? ?? 4,
        difficulty: json['difficulty'] as String,
        tags: json['tags'] as String?,
        photoUrl: json['photoUrl'] as String?,
        isFamilyFavorite: json['isFamilyFavorite'] as bool? ?? false,
        createdById: json['createdById'] as String,
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'instructions': instructions,
        'prepTimeMinutes': prepTimeMinutes,
        'servings': servings,
        'difficulty': difficulty,
        'tags': tags,
        'photoUrl': photoUrl,
        'isFamilyFavorite': isFamilyFavorite,
      };
}

class MealPlanEntry {
  final String id;
  final String mealPlanId;
  final int dayOfWeek;
  final String mealType;
  final String? recipeId;
  final String? title;
  final String? recipeTitle;
  final int sortOrder;

  MealPlanEntry({
    required this.id,
    required this.mealPlanId,
    required this.dayOfWeek,
    required this.mealType,
    this.recipeId,
    this.title,
    this.recipeTitle,
    this.sortOrder = 0,
  });

  factory MealPlanEntry.fromJson(Map<String, dynamic> json) => MealPlanEntry(
        id: json['id'] as String,
        mealPlanId: json['mealPlanId'] as String,
        dayOfWeek: json['dayOfWeek'] as int,
        mealType: json['mealType'] as String,
        recipeId: json['recipeId'] as String?,
        title: json['title'] as String?,
        recipeTitle: json['recipeTitle'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class MealPlan {
  final String id;
  final String weekStart;
  final String weekEnd;
  final String createdById;
  final List<MealPlanEntry> entries;

  MealPlan({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.createdById,
    this.entries = const [],
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        weekStart: json['weekStart'] as String,
        weekEnd: json['weekEnd'] as String,
        createdById: json['createdById'] as String,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => MealPlanEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class MealVote {
  final String id;
  final String mealPlanEntryId;
  final String familyMemberId;
  final int preference;
  final String createdAt;

  MealVote({
    required this.id,
    required this.mealPlanEntryId,
    required this.familyMemberId,
    required this.preference,
    required this.createdAt,
  });

  factory MealVote.fromJson(Map<String, dynamic> json) => MealVote(
        id: json['id'] as String,
        mealPlanEntryId: json['mealPlanEntryId'] as String,
        familyMemberId: json['familyMemberId'] as String,
        preference: json['preference'] as int,
        createdAt: json['createdAt'] as String,
      );
}

class VoteInfo {
  final String memberId;
  final String memberName;
  final int preference;

  VoteInfo({
    required this.memberId,
    required this.memberName,
    required this.preference,
  });

  factory VoteInfo.fromJson(Map<String, dynamic> json) => VoteInfo(
        memberId: json['memberId'] as String,
        memberName: json['memberName'] as String,
        preference: json['preference'] as int,
      );
}

class VoteTally {
  final String entryId;
  final String mealType;
  final int dayOfWeek;
  final String? recipeTitle;
  final List<VoteInfo> votes;
  final int totalVotes;

  VoteTally({
    required this.entryId,
    required this.mealType,
    required this.dayOfWeek,
    this.recipeTitle,
    this.votes = const [],
    this.totalVotes = 0,
  });

  factory VoteTally.fromJson(Map<String, dynamic> json) => VoteTally(
        entryId: json['entryId'] as String,
        mealType: json['mealType'] as String,
        dayOfWeek: json['dayOfWeek'] as int,
        recipeTitle: json['recipeTitle'] as String?,
        votes: (json['votes'] as List<dynamic>?)
                ?.map((v) => VoteInfo.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
        totalVotes: json['totalVotes'] as int? ?? 0,
      );
}

// ── Service ──

class MealsService {
  final Dio _dio;
  MealsService(this._dio);

  // ── Recipes ──

  Future<List<Recipe>> getRecipes({bool? familyFavorites, String? tag}) async {
    final queryParams = <String, dynamic>{};
    if (familyFavorites == true) queryParams['familyFavorites'] = true;
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    final res = await _dio.get('/api/recipes', queryParameters: queryParams);
    return (res.data as List).map((j) => Recipe.fromJson(j)).toList();
  }

  Future<Recipe> getRecipe(String id) async {
    final res = await _dio.get('/api/recipes/$id');
    return Recipe.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createRecipe({
    required String title,
    String? description,
    required String ingredients,
    required String instructions,
    int prepTimeMinutes = 30,
    int servings = 4,
    String difficulty = 'Easy',
    String? tags,
    String? photoUrl,
    bool isFamilyFavorite = false,
  }) async {
    final res = await _dio.post('/api/recipes', data: {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'tags': tags,
      'photoUrl': photoUrl,
      'isFamilyFavorite': isFamilyFavorite,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRecipe(
    String id, {
    String? title,
    String? description,
    String? ingredients,
    String? instructions,
    int? prepTimeMinutes,
    int? servings,
    String? difficulty,
    String? tags,
    String? photoUrl,
    bool? isFamilyFavorite,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (ingredients != null) data['ingredients'] = ingredients;
    if (instructions != null) data['instructions'] = instructions;
    if (prepTimeMinutes != null) data['prepTimeMinutes'] = prepTimeMinutes;
    if (servings != null) data['servings'] = servings;
    if (difficulty != null) data['difficulty'] = difficulty;
    if (tags != null) data['tags'] = tags;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (isFamilyFavorite != null) data['isFamilyFavorite'] = isFamilyFavorite;
    final res = await _dio.put('/api/recipes/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteRecipe(String id) async {
    await _dio.delete('/api/recipes/$id');
  }

  // ── Meal Plans ──

  Future<List<MealPlan>> getMealPlans({String? weekStart}) async {
    final queryParams = <String, dynamic>{};
    if (weekStart != null) queryParams['weekStart'] = weekStart;
    final res = await _dio.get('/api/meal-plans', queryParameters: queryParams);
    return (res.data as List).map((j) => MealPlan.fromJson(j)).toList();
  }

  Future<MealPlan> getMealPlan(String id) async {
    final res = await _dio.get('/api/meal-plans/$id');
    return MealPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createMealPlan(String weekStart) async {
    final res = await _dio.post('/api/meal-plans', data: {
      'weekStart': weekStart,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addEntry(
    String mealPlanId, {
    required int dayOfWeek,
    required String mealType,
    String? recipeId,
    String? title,
  }) async {
    final res = await _dio.put('/api/meal-plans/$mealPlanId/entries', data: {
      'dayOfWeek': dayOfWeek,
      'mealType': mealType,
      'recipeId': recipeId,
      'title': title,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> removeEntry(String mealPlanId, String entryId) async {
    await _dio.delete('/api/meal-plans/$mealPlanId/entries/$entryId');
  }

  // ── Voting ──

  Future<Map<String, dynamic>> castVote(
      String mealPlanId, String entryId, int preference) async {
    final res = await _dio.post(
        '/api/meal-plans/$mealPlanId/entries/$entryId/vote',
        data: {'preference': preference});
    return res.data as Map<String, dynamic>;
  }

  Future<VoteTally> getVotes(String mealPlanId, String entryId) async {
    final res =
        await _dio.get('/api/meal-plans/$mealPlanId/entries/$entryId/votes');
    return VoteTally.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Toggle Favorite ──

  Future<Map<String, dynamic>> toggleFavorite(String recipeId) async {
    final res = await _dio.post('/api/recipes/$recipeId/toggle-favorite');
    return res.data as Map<String, dynamic>;
  }
}

// ── Providers ──

final mealsServiceProvider = Provider<MealsService>((ref) {
  return MealsService(ref.watch(authenticatedDioProvider));
});

final recipesListProvider = FutureProvider<List<Recipe>>((ref) {
  return ref.watch(mealsServiceProvider).getRecipes();
});

final familyFavoritesListProvider = FutureProvider<List<Recipe>>((ref) {
  return ref.watch(mealsServiceProvider).getRecipes(familyFavorites: true);
});

final mealPlansListProvider =
    FutureProvider.family<List<MealPlan>, String?>((ref, weekStart) {
  return ref.watch(mealsServiceProvider).getMealPlans(weekStart: weekStart);
});
