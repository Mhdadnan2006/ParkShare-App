import 'package:flutter/material.dart';

class BookingCalculator {
  static double calculateCost(String priceStr, TimeOfDay startTime, TimeOfDay endTime) {
    double price = double.tryParse(priceStr) ?? 5.0;
    double hours = (endTime.hour - startTime.hour) + (endTime.minute - startTime.minute) / 60.0;
    if (hours <= 0) hours = 1;
    return price * hours;
  }
}
