/**
 * @file Noogle grammar for tree-sitter
 * @author Ivan <ivannovitskii@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const decimalDigitSequence = /([0-9][0-9_]*[0-9]|[0-9])/;

module.exports = grammar({
  name: "noogle",
  extras: (_) => ["\r", " "],
  word: $ => $.identifier,

  rules: {
    source_file: $ => repeat($.definition),
    definition: $ => seq($.path, $.signature, "\n"),
    path: $ => seq(
      field("namespace", $.namespace_part), 
      ".", 
      field("class", $.identifier)),

    namespace_part: $ => choice(
      seq($.namespace_part, ".", $.identifier),
      $.identifier
    ),

    def_name: $ => seq(
      optional(seq(
        $.namespace_part, 
        "."
      )),
      $.identifier
    ),

    signature: $ => choice(
      $.property_signature,
      $.method_signature,
      $.enum_signature,
    ),

    property_signature: $ => seq(
      $.accessibility,
      optional("static"),
      field("return_type", $.type),
      field("name", $.def_name), 
      optional(seq(
        "{",
        optional($.getter),
        optional($.setter),
        "}"
      )),
    ),
    getter: $ => seq(
      optional($.accessibility),
      "get",
      ";"
    ),
    setter: $ => seq(
      optional($.accessibility),
      "set",
      ";"
    ),

    accessibility: $ => choice(
      "none",
      "private", 
      "protectedandinternal", 
      "protected", 
      "internal", 
      "protectedorinternal", 
      "public"
    ),

    method_signature: $ => seq(
      $.accessibility,
      optional("static"),
      field("return_type", $.type),
      field("name", choice($.def_name, '.ctor')), 
      "(",
      field("parameters", optional($.arg_list)),
      ")",
    ),

    arg_list: $ => choice(
      seq($.arg_list, ",", $.arg),
      $.arg
    ),
    arg: $ => seq(
      field("arg_type", $.type),
      field("arg_name", $.identifier),
      optional(seq("=", $.default_value))
    ),

    enum_signature: $ => seq(
      "enum",
      field("enum", $.identifier),
      ".",
      field("field", $.identifier),
      optional(seq("=", $.default_value))
    ),

    type_list: $ => choice(
      seq($.type_list, ",", $.type),
      $.type
    ),
    type: $ => seq(
      choice($.generic_type, $.simple_type), 
      optional($._array_modifier),
      optional($._ref_modifier)
    ),
    _array_modifier: $ => repeat1(seq('[', optional($._commas), ']')),
    _ref_modifier: $ => repeat1($._refs),
    generic_type: $ => seq($.simple_type, "<", $.type_list, ">"),
    simple_type: $ => $.identifier,

    default_value: $ => choice(
      $.char_literal,
      $.string_literal,
      $.integer_literal,
      $.real_literal,
      $.negative_literal,
      $.null_literal,
      $.boolean_literal,
      // $.identifier
    ),

    null_literal: $ => "null",
    char_literal: $ => seq(
      '\'',
      choice($.character_literal_content, $.escape_sequence),
      '\'',
    ),
    character_literal_content: $ => token.immediate(/[^'\\]/),

    string_literal: $ => seq(
      '"',
      repeat(choice(
        $.string_literal_content,
        $.escape_sequence,
      )),
      '"'
    ),
    string_literal_content: $ => choice(
      token.immediate(prec(1, /[^"\\\n]+/)),
      prec(2, token.immediate(seq('\\', /[^abefnrtv'\"\\\?0]/))),
    ),
    escape_sequence: $ => token(choice(
      /\\x[0-9a-fA-F]{2,4}/,
      /\\u[0-9a-fA-F]{4}/,
      /\\U[0-9a-fA-F]{8}/,
      /\\[abefnrtv'\"\\\?0]/,
    )),

    integer_literal: $ => token(seq(
      choice(
        decimalDigitSequence, // Decimal
        (/0[xX][0-9a-fA-F_]*[0-9a-fA-F]+/), // Hex
        (/0[bB][01_]*[01]+/), // Binary
      ),
      optional(/([uU][lL]?|[lL][uU]?)/),
    )),

    real_literal: $ => {
      const suffix = /[fFdDmM]/;
      const exponent = /[eE][+-]?[0-9][0-9_]*/;
      return token(choice(
        seq(
          decimalDigitSequence,
          '.',
          decimalDigitSequence,
          optional(exponent),
          optional(suffix),
        ),
        seq(
          '.',
          decimalDigitSequence,
          optional(exponent),
          optional(suffix),
        ),
        seq(
          decimalDigitSequence,
          exponent,
          optional(suffix),
        ),
        seq(
          decimalDigitSequence,
          suffix,
        ),
      ));
    },

    negative_literal: $ => seq('-', choice($.integer_literal, $.real_literal)),

    boolean_literal: $ => choice('true', 'false'),

    identifier: $ => /[a-zA-Z0-9_-]+/,
    _commas: $ => /[,]+/,
    _refs: $ => /[*&]+/,
  }
});
