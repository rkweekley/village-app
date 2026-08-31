import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:village_app/features/rewards/rewards_service.dart';

void main() {
  group('createReward validation (guards run before HTTP)', () {
    test('rejects a blank name', () {
      expect(
        () => RewardsService(Dio()).createReward(name: '   ', pointCost: 10),
        throwsArgumentError,
      );
    });

    test('rejects an empty name', () {
      expect(
        () => RewardsService(Dio()).createReward(name: '', pointCost: 10),
        throwsArgumentError,
      );
    });

    test('rejects a point cost below 1', () {
      expect(
        () => RewardsService(Dio())
            .createReward(name: 'Ice cream', pointCost: 0),
        throwsArgumentError,
      );
    });
  });

  group('updateReward validation', () {
    test('rejects a blank name when provided', () {
      expect(
        () => RewardsService(Dio()).updateReward('abc', name: '  '),
        throwsArgumentError,
      );
    });

    test('rejects a point cost below 1 when provided', () {
      expect(
        () => RewardsService(Dio()).updateReward('abc', pointCost: -1),
        throwsArgumentError,
      );
    });
  });
}