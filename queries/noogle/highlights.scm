(char_literal) @string
(string_literal) @string

[
  (real_literal)
  (integer_literal)
  (negative_literal)
] @number

[
  (boolean_literal)
  (null_literal)
] @constant.builtin

(simple_type) @type

(enum_signature
  enum: (identifier) @type)
(enum_signature
  field: (identifier) @property.definition)

(method_signature
  name: (def_name) @function)

(property_signature
  name: (def_name) @property.definition)

(path 
  class: (identifier) @type)

(namespace_part (identifier) @module)

[
  "."
  ";"
  ","
] @punctuation.delimiter

[
 "public"
 "private"
 "protected"
 "internal"
 "static"
] @keyword.modifier

[
 "get"
 "set"
 "enum"
 ".ctor"
] @keyword

[
 "="
] @operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
]  @punctuation.bracket

(arg
  arg_name: (identifier) @variable.parameter)
