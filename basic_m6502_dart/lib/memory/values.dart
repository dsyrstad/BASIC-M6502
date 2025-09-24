/// Re-export of value classes from variables.dart
/// This file provides backward compatibility for tests that import values.dart
library values;

export 'variables.dart'
    show VariableValue, NumericValue, StringValue, TabValue, SpcValue;
