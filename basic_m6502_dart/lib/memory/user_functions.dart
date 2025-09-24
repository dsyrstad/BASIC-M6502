/// User-defined function storage and management for DEF FN statements
library;

/// Represents a user-defined function created with DEF FN
class UserFunction {
  /// Function name (single letter A-Z)
  final String name;

  /// Parameter name (single letter variable)
  final String parameter;

  /// Tokenized expression that defines the function
  final List<int> expression;

  /// Whether this is a string function (name ends with $)
  final bool isStringFunction;

  UserFunction({
    required this.name,
    required this.parameter,
    required this.expression,
    required this.isStringFunction,
  });

  @override
  String toString() {
    return 'UserFunction($name, param: $parameter, isString: $isStringFunction)';
  }
}

/// Storage and management for user-defined functions
class UserFunctionStorage {
  /// Map of function names to their definitions
  final Map<String, UserFunction> _functions = {};

  /// Define a new function
  void defineFunction(UserFunction function) {
    _functions[function.name] = function;
  }

  /// Check if a function is defined
  bool isDefined(String name) {
    return _functions.containsKey(name);
  }

  /// Get a function definition
  UserFunction? getFunction(String name) {
    return _functions[name];
  }

  /// Remove all function definitions
  void clear() {
    _functions.clear();
  }

  /// Get all defined function names
  List<String> getDefinedFunctions() {
    return _functions.keys.toList()..sort();
  }

  /// Get count of defined functions
  int get count => _functions.length;

  @override
  String toString() {
    return 'UserFunctionStorage(${_functions.length} functions: ${getDefinedFunctions().join(', ')})';
  }
}
