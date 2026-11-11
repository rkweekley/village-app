import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:village_app/features/meals/recipe_ideas_service.dart';

/// Serves a canned JSON body for every request.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.statusCode = 200});

  final Object? body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

RecipeIdeasService _service(Object? body, {int statusCode = 200}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = _StubAdapter(body, statusCode: statusCode);
  return RecipeIdeasService(dio);
}

void main() {
  group('recipe list parsing tolerates malformed records (#109)', () {
    test('a null image does not fail the whole list', () async {
      // The old parser did `json['image'] as String`, so one null image threw
      // and every recipe in the response disappeared.
      final recipes = await _service([
        {'id': '1', 'title': 'Chicken Pie', 'image': null},
      ]).search('pie');

      expect(recipes, hasLength(1));
      expect(recipes.single.image, '');
      expect(recipes.single.hasImage, isFalse);
    });

    test('numeric ids are stringified, not cast', () async {
      final recipes = await _service([
        {'id': 12345, 'title': 'Stew', 'image': 'https://x/y.jpg'},
      ]).search('stew');

      expect(recipes.single.id, '12345');
    });

    test('a non-object entry is skipped, the rest survive', () async {
      final recipes = await _service([
        'not a recipe',
        null,
        {'id': '2', 'title': 'Bread', 'image': 'https://x/b.jpg'},
      ]).search('bread');

      expect(recipes.map((r) => r.title), ['Bread']);
    });

    test('an entry with no id is dropped rather than rendered dead', () async {
      final recipes = await _service([
        {'title': 'No id', 'image': 'https://x/n.jpg'},
        {'id': '3', 'title': 'Kept', 'image': 'https://x/k.jpg'},
      ]).search('x');

      expect(recipes.map((r) => r.id), ['3']);
    });

    test('malformed ingredients drop rows, not the recipe', () async {
      final recipes = await _service([
        {
          'id': '4',
          'title': 'Soup',
          'image': 'https://x/s.jpg',
          'ingredients': [
            {'name': 'Water', 'measure': '1 cup'},
            null,
            {'measure': 'no name'},
            {'name': 'Salt', 'measure': null},
          ],
        },
      ]).search('soup');

      expect(recipes.single.ingredients.map((i) => i.name), ['Water', 'Salt']);
      expect(recipes.single.ingredients.last.measure, '');
    });

    test('a non-list payload returns empty instead of throwing', () async {
      final recipes = await _service({'message': 'nope'}).search('x');

      expect(recipes, isEmpty);
    });

    test('category results do not require ingredient payloads', () async {
      final recipes = await _service([
        {'id': '5', 'title': 'Beef Stew', 'image': 'https://x/b.jpg'},
      ]).byCategory('Beef');

      expect(recipes.single.title, 'Beef Stew');
      expect(recipes.single.ingredients, isEmpty);
    });

    test('categories skip entries with no id', () async {
      final categories = await _service([
        {'id': 'Beef', 'name': 'Beef'},
        {'name': 'Orphan'},
      ]).getCategories();

      expect(categories.map((c) => c.id), ['Beef']);
    });
  });

  group('recipe detail parsing', () {
    test('falls back to the requested id when the payload omits it', () async {
      final recipe = await _service({
        'title': 'Pie',
        'image': 'https://x/p.jpg',
      }).getDetail('42');

      expect(recipe.id, '42');
      expect(recipe.title, 'Pie');
    });

    test('a non-object detail payload raises a DioException', () async {
      expect(
        () => _service(['unexpected']).getDetail('42'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
