#!/usr/bin/ruby

require 'fileutils'
require_relative "lib/bookdown/parser"

include FileUtils

mkdir_p "dist"
rm_rf "work"
mkdir_p "work"

ARGV.each do |input|
  puts "Processing #{input}..."
  Bookdown::Parser.new.parse(input)
end
