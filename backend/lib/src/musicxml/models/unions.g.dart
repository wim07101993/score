// ignore_for_file: unused_import, always_use_package_imports, camel_case_types
import 'barrel.g.dart';

/// The font-size can be one of the CSS font sizes (xx-small, x-small, small, medium, large, x-large, xx-large) or a numeric point size.
sealed class FontSize {
  const factory FontSize.double(double value) = FontSize_double;
  const factory FontSize.cssFontSize(CssFontSize value) = FontSize_CssFontSize;
}

class FontSize_double implements FontSize {
  const FontSize_double(this.value);

  final double value;
}
class FontSize_CssFontSize implements FontSize {
  const FontSize_CssFontSize(this.value);

  final CssFontSize value;
}

/// The number-or-normal values can be either a decimal number or the string "normal". This is used by the line-height and letter-spacing attributes.
sealed class NumberOrNormal {
  const factory NumberOrNormal.double(double value) = NumberOrNormal_double;
}

class NumberOrNormal_double implements NumberOrNormal {
  const NumberOrNormal_double(this.value);

  final double value;
}

/// The positive-integer-or-empty values can be either a positive integer or an empty string.
sealed class PositiveIntegerOrEmpty {
  const factory PositiveIntegerOrEmpty.int(int value) = PositiveIntegerOrEmpty_int;
}

class PositiveIntegerOrEmpty_int implements PositiveIntegerOrEmpty {
  const PositiveIntegerOrEmpty_int(this.value);

  final int value;
}

/// The yes-no-number type is used for attributes that can be either boolean or numeric values.
sealed class YesNoNumber {
  const factory YesNoNumber.yesNo(YesNo value) = YesNoNumber_YesNo;
  const factory YesNoNumber.double(double value) = YesNoNumber_double;
}

class YesNoNumber_YesNo implements YesNoNumber {
  const YesNoNumber_YesNo(this.value);

  final YesNo value;
}
class YesNoNumber_double implements YesNoNumber {
  const YesNoNumber_double(this.value);

  final double value;
}
