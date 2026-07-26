import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:village_app/shared/utils/color_utils.dart';

void main() {
  group('parseColor', () {
    test('parses 6-digit hex codes with # prefix', () {
      final color = parseColor('#FF0000');
      expect(color.toARGB32(), 0xFFFF0000);
    });

    test('parses 6-digit hex codes without # prefix', () {
      final color = parseColor('00FF00');
      expect(color.toARGB32(), 0xFF00FF00);
    });

    test('parses 8-digit hex codes (includes alpha)', () {
      final color = parseColor('#800000FF');
      expect(color.toARGB32(), 0x800000FF);
    });

    test('parses 3-digit shorthand hex codes', () {
      final color = parseColor('#F00');
      expect(color.toARGB32(), 0xFFFF0000);
    });

    test('parses 3-digit without # prefix', () {
      final color = parseColor('F00');
      expect(color.toARGB32(), 0xFFFF0000);
    });

    test('parses named color "blue"', () {
      final color = parseColor('blue');
      expect(color.toARGB32(), Colors.blue.toARGB32());
    });

    test('parses named color "red"', () {
      final color = parseColor('red');
      expect(color.toARGB32(), Colors.red.toARGB32());
    });

    test('parses named color "green"', () {
      final color = parseColor('green');
      expect(color.toARGB32(), Colors.green.toARGB32());
    });

    test('returns Material blue fallback for unknown input', () {
      final color = parseColor('not-a-color');
      expect(color.toARGB32(), Colors.blue.toARGB32());
    });

    test('handles empty string', () {
      final color = parseColor('');
      expect(color.toARGB32(), Colors.blue.toARGB32());
    });

    test('handles null', () {
      final color = parseColor(null);
      expect(color.toARGB32(), Colors.blue.toARGB32());
    });

    test('handles named colors case-insensitively', () {
      expect(parseColor('PURPLE').toARGB32(), Colors.purple.toARGB32());
      expect(parseColor('Deep_Purple').toARGB32(), Colors.deepPurple.toARGB32());
      expect(parseColor('GREY').toARGB32(), Colors.grey.toARGB32());
    });
  });
}
