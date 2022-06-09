import 'package:flutter/material.dart';

extension MediaQueryExtensions on MediaQueryData {
  bool isMobile() => size.shortestSide < 600;
}
