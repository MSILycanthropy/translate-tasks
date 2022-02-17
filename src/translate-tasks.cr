require "yaml"
require "json/builder"
require "benchmark"
require "dir"
require "path"
require "colorize"
require "option_parser"
require "terminal_table"
require "./parser"
require "./node"
require "./tree"
require "./config"
require "./settings"
require "./scanner"
require "./result"

ActionParser.parse
