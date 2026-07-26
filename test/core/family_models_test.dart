import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/features/family/models.dart';

void main() {
  group('MemberInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '123',
        'displayName': 'Alice',
        'email': 'alice@test.com',
        'role': 'parent',
        'pointsBalance': 100,
        'birthDate': '2010-05-15',
      };
      final m = MemberInfo.fromJson(json);
      expect(m.id, '123');
      expect(m.displayName, 'Alice');
      expect(m.email, 'alice@test.com');
      expect(m.role, 'parent');
      expect(m.pointsBalance, 100);
      expect(m.birthDate, '2010-05-15');
    });

    test('fromJson handles missing birthDate', () {
      final json = {
        'id': '456',
        'displayName': 'Bob',
        'email': 'bob@test.com',
        'role': 'child',
        'pointsBalance': 50,
      };
      final m = MemberInfo.fromJson(json);
      expect(m.id, '456');
      expect(m.birthDate, isNull);
    });
  });

  group('FamilyInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'family-1',
        'name': 'Smith Family',
        'inviteCode': 'ABC123',
        'currencyName': 'Points',
        'timezone': 'America/New_York',
        'members': [
          {'id': 'm1', 'displayName': 'Mom', 'email': 'mom@t.com',
           'role': 'parent', 'pointsBalance': 200},
          {'id': 'm2', 'displayName': 'Kid', 'email': 'kid@t.com',
           'role': 'child', 'pointsBalance': 75},
        ],
      };
      final f = FamilyInfo.fromJson(json);
      expect(f.id, 'family-1');
      expect(f.members.length, 2);
      expect(f.members[0].displayName, 'Mom');
      expect(f.members[1].pointsBalance, 75);
    });

    test('fromJson defaults when fields are null', () {
      final json = {
        'id': 'f2',
        'name': 'Test',
        'inviteCode': 'XYZ',
        'members': null,
      };
      final f = FamilyInfo.fromJson(json);
      expect(f.members, isEmpty);
      expect(f.currencyName, 'Points');
      expect(f.timezone, 'America/New_York');
    });
  });
}
