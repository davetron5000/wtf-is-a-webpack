#!/usr/bin/env ruby
#

require "pathname"
require "fileutils"

include FileUtils

Dir["lib/**/*.rb"].each do |file|
  spec_file = Pathname(file.gsub(/lib\/bookdown/,"spec").gsub(/\.rb$/,"_spec.rb"))
  require_file = file.gsub(/lib\//,"").gsub(/^\//,"").gsub(/\.rb$/,"")
  raise unless spec_file.to_s =~ /_spec.rb$/
  path = spec_file.dirname
  mkdir_p path
  class_name = nil
  modules = []
  methods = []
  File.open(file).readlines.each do |line|
    break if line =~ /^\s*private/
    if line =~ /module\s+([\w:]+)/
      modules << $1
    elsif line =~ /class\s+([\w:]+)/ && class_name.nil?
      class_name = $1
    elsif line =~ /def\s+([\w_]+)/
      methods << $1
    end
  end
  class_name = modules.join("::") + "::" + class_name unless modules.empty?
  if class_name.nil?
    puts "Can't figure out class from file #{file}"
  else
    puts "Creating shell spec for #{class_name}"
    File.open(spec_file,"w") do |file|
      file.puts "require \"spec_helper\""
      file.puts "require \"#{require_file}\""
      file.puts
      file.puts "RSpec.describe #{class_name} do"
      methods.each do |method|
        file.puts "  describe \"##{method}\" do"
        file.puts "    pending"
        file.puts "  end"
      end
      file.puts "end"
    end
  end
end
