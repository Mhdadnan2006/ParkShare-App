import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkshare_app/core/utils/booking_calculator.dart';

void main() {
  group('BookingCalculator Tests', () {
    test('calculates correct cost for full hours', () {
      final start = TimeOfDay(hour: 10, minute: 0);
      final end = TimeOfDay(hour: 12, minute: 0);
      final cost = BookingCalculator.calculateCost('5.0', start, end);
      expect(cost, 10.0);
    });

    test('calculates correct cost for partial hours', () {
      final start = TimeOfDay(hour: 10, minute: 0);
      final end = TimeOfDay(hour: 11, minute: 30);
      final cost = BookingCalculator.calculateCost('5.0', start, end);
      expect(cost, 7.5);
    });

    test('defaults to 1 hour if end time is before start time', () {
      final start = TimeOfDay(hour: 10, minute: 0);
      final end = TimeOfDay(hour: 9, minute: 0);
      final cost = BookingCalculator.calculateCost('5.0', start, end);
      expect(cost, 5.0);
    });

    test('handles invalid price string gracefully', () {
      final start = TimeOfDay(hour: 10, minute: 0);
      final end = TimeOfDay(hour: 12, minute: 0);
      final cost = BookingCalculator.calculateCost('invalid', start, end);
      expect(cost, 10.0); // Defaults to 5.0 * 2
    });
  });
}
