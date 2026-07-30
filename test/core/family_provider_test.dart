import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/features/family/family_provider.dart';
import 'package:village_app/features/family/models.dart';

void main() {
  group('FamilyState', () {
    test('default state has no family data', () {
      const state = FamilyState();
      expect(state.family, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith updates individual fields', () {
      const state = FamilyState();
      final updated = state.copyWith(
        isLoading: true,
        error: 'test error',
      );
      expect(updated.isLoading, true);
      expect(updated.error, 'test error');
      expect(updated.family, isNull);
    });

    test('copyWith clears error when passing null error', () {
      final state = const FamilyState().copyWith(error: 'old error');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('FamilyInfo.fromJson', () {
    test('parses family with members from JSON', () {
      final json = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'name': 'Test Family',
        'inviteCode': 'ABCD1234',
        'currencyName': 'Stars',
        'timezone': 'America/Chicago',
        'members': [
          {
            'id': '1',
            'displayName': 'Alice',
            'email': 'alice@test.com',
            'role': 'Parent',
            'pointsBalance': 500,
          },
          {
            'id': '2',
            'displayName': 'Bob',
            'email': 'bob@test.com',
            'role': 'Child',
            'pointsBalance': 120,
          },
        ],
      };
      final family = FamilyInfo.fromJson(json);
      expect(family.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(family.name, 'Test Family');
      expect(family.inviteCode, 'ABCD1234');
      expect(family.currencyName, 'Stars');
      expect(family.timezone, 'America/Chicago');
      expect(family.members.length, 2);
      expect(family.members[0].displayName, 'Alice');
      expect(family.members[0].role, 'Parent');
      expect(family.members[0].pointsBalance, 500);
      expect(family.members[1].displayName, 'Bob');
      expect(family.members[1].role, 'Child');
      expect(family.members[1].pointsBalance, 120);
    });

    test('currencyName defaults to Points when missing', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'inviteCode': 'CODE',
        'timezone': 'UTC',
        'members': [],
      };
      final family = FamilyInfo.fromJson(json);
      expect(family.currencyName, 'Points');
    });

    test('timezone defaults to America/New_York when missing', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'inviteCode': 'CODE',
        'members': [],
      };
      final family = FamilyInfo.fromJson(json);
      expect(family.timezone, 'America/New_York');
    });

    test('members defaults to empty list when null', () {
      final json = {
        'id': '1',
        'name': 'Test',
        'inviteCode': 'CODE',
      };
      final family = FamilyInfo.fromJson(json);
      expect(family.members, isEmpty);
    });
  });

  group('MemberInfo.fromJson', () {
    test('parses member from JSON', () {
      final json = {
        'id': '1',
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'role': 'Parent',
        'pointsBalance': 500,
        'birthDate': '2014-05-12',
      };
      final member = MemberInfo.fromJson(json);
      expect(member.id, '1');
      expect(member.displayName, 'Alice');
      expect(member.email, 'alice@test.com');
      expect(member.role, 'Parent');
      expect(member.pointsBalance, 500);
      expect(member.birthDate, '2014-05-12');
    });

    test('pointsBalance defaults to 0 when missing', () {
      final member = MemberInfo.fromJson({
        'id': '1',
        'displayName': 'Test',
        'email': 't@t.com',
        'role': 'Child',
      });
      expect(member.pointsBalance, 0);
    });

    test('birthDate is null when not present', () {
      final member = MemberInfo.fromJson({
        'id': '1',
        'displayName': 'Test',
        'email': 't@t.com',
        'role': 'Child',
        'pointsBalance': 0,
      });
      expect(member.birthDate, isNull);
    });
  });

  group('InviteCodeLookup.fromJson', () {
    test('parses invite code lookup from JSON', () {
      final json = {
        'id': '1',
        'name': 'Smith Family',
        'inviteCode': 'VILLAGE1',
        'memberCount': 4,
      };
      final lookup = InviteCodeLookup.fromJson(json);
      expect(lookup.id, '1');
      expect(lookup.name, 'Smith Family');
      expect(lookup.inviteCode, 'VILLAGE1');
      expect(lookup.memberCount, 4);
    });
  });
}
