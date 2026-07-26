import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:village_app/core/network/authenticated_client.dart';

// ── Models ──

class ShoppingListSummary {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final int itemCount;
  final int checkedCount;

  ShoppingListSummary({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.itemCount,
    required this.checkedCount,
  });

  factory ShoppingListSummary.fromJson(Map<String, dynamic> json) =>
      ShoppingListSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        itemCount: json['itemCount'] as int,
        checkedCount: json['checkedCount'] as int,
      );
}

class ShoppingItem {
  final String id;
  final String name;
  final String? category;
  final int quantity;
  final String? unit;
  bool isChecked;
  final String? checkedByUserId;
  final String? checkedAt;
  final int sortOrder;

  ShoppingItem({
    required this.id,
    required this.name,
    this.category,
    required this.quantity,
    this.unit,
    required this.isChecked,
    this.checkedByUserId,
    this.checkedAt,
    required this.sortOrder,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        unit: json['unit'] as String?,
        isChecked: json['isChecked'] as bool,
        checkedByUserId: json['checkedByUserId'] as String?,
        checkedAt: json['checkedAt'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class ShoppingListDetail {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;
  final List<ShoppingItem> items;

  ShoppingListDetail({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory ShoppingListDetail.fromJson(Map<String, dynamic> json) =>
      ShoppingListDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        items: (json['items'] as List)
            .map((i) => ShoppingItem.fromJson(i))
            .toList(),
      );

  int get itemCount => items.length;
  int get checkedCount => items.where((i) => i.isChecked).length;
}

// ── Service ──

class ShoppingService {
  final Dio _dio;
  ShoppingService(this._dio);

  Future<List<ShoppingListSummary>> getLists() async {
    final res = await _dio.get('/api/shopping');
    return (res.data as List)
        .map((j) => ShoppingListSummary.fromJson(j))
        .toList();
  }

  Future<Map<String, dynamic>> createList(String name) async {
    final res = await _dio.post('/api/shopping', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }

  Future<ShoppingListDetail> getList(String id) async {
    final res = await _dio.get('/api/shopping/$id');
    return ShoppingListDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteList(String id) async {
    await _dio.delete('/api/shopping/$id');
  }

  Future<Map<String, dynamic>> addItem(
    String listId, {
    required String name,
    String? category,
    int quantity = 1,
    String? unit,
  }) async {
    final res = await _dio.post('/api/shopping/$listId/items', data: {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleItem(String listId, String itemId) async {
    final res =
        await _dio.put('/api/shopping/$listId/items/$itemId/toggle');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateItem(
    String listId,
    String itemId, {
    String? name,
    String? category,
    int? quantity,
    String? unit,
  }) async {
    final res = await _dio.put('/api/shopping/$listId/items/$itemId', data: {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteItem(String listId, String itemId) async {
    await _dio.delete('/api/shopping/$listId/items/$itemId');
  }
}

// ── Provider ──

final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService(ref.watch(authenticatedDioProvider));
});

final shoppingListsProvider = FutureProvider<List<ShoppingListSummary>>((ref) {
  return ref.watch(shoppingServiceProvider).getLists();
});
