-- ~/.config/nvim/lua/snippets/cpp.lua
local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.conditions")
local conds_expand = require("luasnip.extras.conditions.expand")

-- Get current filename without extension
local function get_filename_without_ext()
  local filename = vim.fn.expand("%:t")
  return filename:gsub("%.%w+$", "")
end

-- Helper function for header guards
local function get_header_guard()
  local filename = vim.fn.expand("%:t")
  local guard = filename:gsub("%.", "_"):upper()
  return guard
end

-- Include snippets
local cpp_snippets = {
  -- Basic include snippet
  s("inc", {
    t("#include <"),
    i(1),
    t(">"),
  }),
  
  -- Include with quotes
  s("incs", {
    t('#include "'),
    i(1),
    t('"'),
  }),
  
  -- Common standard includes with choices
  s("incstd", {
    t("#include <"),
    c(1, {
      t("iostream"),
      t("vector"),
      t("string"),
      t("algorithm"),
      t("memory"),
      t("map"),
      t("unordered_map"),
      t("set"),
      t("unordered_set"),
      t("utility"), -- for std::pair, std::move, etc.
      t("functional"), -- for std::function, std::bind, etc.
      t("thread"),
      t("chrono"),
      t("fstream"),
      t("sstream"),
      t("numeric"), -- for std::accumulate, etc.
    }),
    t(">"),
  }),
  
  -- Common iostream includes
  s("incio", {
    t({"#include <iostream>", ""}),
  }),

  -- Classes and structures
  s("class", {
    t("class "),
    i(1, "ClassName"),
    t(" {"),
    t({"", "public:"}),
    t({"", "\t"}),
    i(2, "ClassName"),
    t("() = default;"),
    t({"", "\t~"}),
    rep(2),
    t("() = default;"),
    t({"", "", "private:"}),
    t({"", "\t"}),
    i(0),
    t({"", "};"}),
  }),
  
  -- Struct snippet
  s("struct", {
    t("struct "),
    i(1, "StructName"),
    t(" {"),
    t({"", "\t"}),
    i(0),
    t({"", "};"}),
  }),
  
  -- Header guard
  s("guard", {
    t("#pragma once"),
    t({"", ""}),
  }),
  
  -- Old style header guard
  s("ifndef", {
    t("#ifndef "),
    f(get_header_guard),
    t({"", "#define "}),
    f(get_header_guard),
    t({"", "", ""}),
    i(0),
    t({"", "", "#endif // "}),
    f(get_header_guard),
  }),
  
  -- Namespace
  s("ns", {
    t("namespace "),
    i(1, "name"),
    t(" {"),
    t({"", ""}),
    i(0),
    t({"", "}  // namespace "}),
    rep(1),
  }),
  
  -- Function implementation
  s("fun", {
    i(1, "void"),
    t(" "),
    i(2, "function_name"),
    t("("),
    i(3),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Function declaration
  s("fund", {
    i(1, "void"),
    t(" "),
    i(2, "function_name"),
    t("("),
    i(3),
    t(");"),
    i(0),
  }),
  
  -- Member function implementation
  s("mfun", {
    i(1, "void"),
    t(" "),
    i(2, "ClassName"),
    t("::"),
    i(3, "function_name"),
    t("("),
    i(4),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Constructors
  s("ctor", {
    i(1, "ClassName"),
    t("::"),
    rep(1),
    t("("),
    i(2),
    t(") : "),
    i(3),
    t(" {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- For loop
  s("for", {
    t("for ("),
    c(1, {
      sn(nil, {
        t("int "),
        i(1, "i"),
        t(" = 0; "),
        rep(1),
        t(" < "),
        i(2, "n"),
        t("; ++"),
        rep(1),
      }),
      sn(nil, {
        t("auto& "),
        i(1, "element"),
        t(" : "),
        i(2, "container"),
      }),
      sn(nil, {
        t("auto "),
        i(1, "it"),
        t(" = "),
        i(2, "container"),
        t(".begin(); "),
        rep(1),
        t(" != "),
        rep(2),
        t(".end(); ++"),
        rep(1),
      }),
    }),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- While loop
  s("while", {
    t("while ("),
    i(1, "condition"),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Do-while loop
  s("do", {
    t("do {"),
    t({"", "\t"}),
    i(0),
    t({"", "} while ("}),
    i(1, "condition"),
    t(");"),
  }),
  
  -- If statement
  s("if", {
    t("if ("),
    i(1, "condition"),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- If-else statement
  s("ife", {
    t("if ("),
    i(1, "condition"),
    t(") {"),
    t({"", "\t"}),
    i(2),
    t({"", "} else {"}),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Switch statement
  s("switch", {
    t("switch ("),
    i(1, "variable"),
    t(") {"),
    t({"", "case "}),
    i(2, "value"),
    t(":");
    t({"", "\t"}),
    i(3),
    t({"", "\tbreak;"}),
    t({"", "default:"}),
    t({"", "\t"}),
    i(0),
    t({"", "\tbreak;"}),
    t({"", "}"}),
  }),
  
  -- Try-catch block
  s("try", {
    t("try {"),
    t({"", "\t"}),
    i(1),
    t({"", "} catch ("}),
    i(2, "const std::exception& e"),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Lambda expression
  s("lambda", {
    t("["),
    i(1),
    t("]("),
    i(2),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Standard main function
  s("main", {
    t({"int main(int argc, char* argv[]) {", "\t"}),
    i(0),
    t({"", "\treturn 0;", "}"}),
  }),
  
  -- Simple main function
  s("smain", {
    t({"int main() {", "\t"}),
    i(0),
    t({"", "\treturn 0;", "}"}),
  }),
  
  -- Custom deleter for unique_ptr
  s("deleter", {
    t("struct "),
    i(1, "CustomDeleter"),
    t(" {"),
    t({"", "\tvoid operator()("}),
    i(2, "Type"),
    t("* ptr) const {"),
    t({"", "\t\t"}),
    i(3, "delete ptr"),
    t(";"),
    t({"", "\t}", "}"}),
    i(0),
  }),
  
  -- Unique pointer
  s("unique", {
    t("std::unique_ptr<"),
    i(1, "Type"),
    c(2, {
      t(""),
      sn(nil, {
        t(", "),
        i(1, "CustomDeleter"),
      }),
    }),
    t("> "),
    i(3, "ptr"),
    c(4, {
      t(""),
      sn(nil, {
        t(" = std::make_unique<"),
        rep(1),
        t(">("),
        i(1),
        t(")"),
      }),
    }),
    t(";"),
    i(0),
  }),
  
  -- Shared pointer
  s("shared", {
    t("std::shared_ptr<"),
    i(1, "Type"),
    t("> "),
    i(2, "ptr"),
    c(3, {
      t(""),
      sn(nil, {
        t(" = std::make_shared<"),
        rep(1),
        t(">("),
        i(1),
        t(")"),
      }),
    }),
    t(";"),
    i(0),
  }),
  
  -- Output to cout
  s("cout", {
    t("std::cout << "),
    i(1),
    t(" << std::endl;"),
    i(0),
  }),
  
  -- Input from cin
  s("cin", {
    t("std::cin >> "),
    i(1),
    t(";"),
    i(0),
  }),
  
  -- Vector initialization
  s("vec", {
    t("std::vector<"),
    i(1, "int"),
    t("> "),
    i(2, "vec"),
    c(3, {
      t(""),
      sn(nil, {
        t("("),
        i(1),
        t(")"),
      }),
      sn(nil, {
        t(" = {"),
        i(1),
        t("}"),
      }),
    }),
    t(";"),
    i(0),
  }),
  
  -- Auto type declaration
  s("auto", {
    t("auto "),
    i(1, "var"),
    t(" = "),
    i(2),
    t(";"),
    i(0),
  }),
  
  -- Typedef
  s("td", {
    t("typedef "),
    i(1, "type"),
    t(" "),
    i(2, "alias"),
    t(";"),
    i(0),
  }),
  
  -- Using alias
  s("using", {
    t("using "),
    i(1, "alias"),
    t(" = "),
    i(2, "type"),
    t(";"),
    i(0),
  }),
  
  -- Template class
  s("tclass", {
    t("template <typename "),
    i(1, "T"),
    t(">"),
    t({"", "class "}),
    i(2, "ClassName"),
    t(" {"),
    t({"", "public:"}),
    t({"", "\t"}),
    rep(2),
    t("() = default;"),
    t({"", "\t~"}),
    rep(2),
    t("() = default;"),
    t({"", "", "private:"}),
    t({"", "\t"}),
    i(0),
    t({"", "};"}),
  }),
  
  -- Template function
  s("tfun", {
    t("template <typename "),
    i(1, "T"),
    t(">"),
    t({"", ""}),
    i(2, "void"),
    t(" "),
    i(3, "function_name"),
    t("("),
    i(4),
    t(") {"),
    t({"", "\t"}),
    i(0),
    t({"", "}"}),
  }),
  
  -- Smart enum (enum class)
  s("enum", {
    t("enum class "),
    i(1, "Name"),
    t(" {"),
    t({"", "\t"}),
    i(2),
    t({"", "};"}),
    i(0),
  }),
  
  -- Static assert
  s("sassert", {
    t("static_assert("),
    i(1, "condition"),
    t(", \""),
    i(2, "message"),
    t("\");"),
    i(0),
  }),
  
  -- Doxygen function comment
  s("docf", {
    t({"/**", " * @brief "}),
    i(1, "Brief description"),
    t({"", " *"}),
    t({"", " * "}),
    i(2, "Detailed description"),
    t({"", " *"}),
    c(3, {
      t(""),
      sn(nil, {
        t({"", " * @param "}),
        i(1, "name"),
        t(" "),
        i(2, "Parameter description"),
      }),
    }),
    c(4, {
      t(""),
      sn(nil, {
        t({"", " * @return "}),
        i(1, "Return description"),
      }),
    }),
    t({"", " */"}),
    i(0),
  }),
  
  -- Doxygen class comment
  s("docc", {
    t({"/**", " * @brief "}),
    i(1, "Brief description"),
    t({"", " *"}),
    t({"", " * "}),
    i(2, "Detailed description"),
    t({"", " *"}),
    c(3, {
      t(""),
      sn(nil, {
        t({"", " * @tparam "}),
        i(1, "T"),
        t(" "),
        i(2, "Template parameter description"),
      }),
    }),
    t({"", " */"}),
    i(0),
  }),
  
  -- Simple comment block
  s("com", {
    t({"/*", " * "}),
    i(1),
    t({"", " */"}),
    i(0),
  }),
}

return cpp_snippets
