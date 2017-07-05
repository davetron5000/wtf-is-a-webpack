require 'pathname'
require_relative "commands/method_call"
require_relative "commands/puts_to_file_io"
require_relative "commands/append_to_file_name"
require_relative "commands/sh"

module Bookdown
  module Directives
    class Graphviz
      def self.recognize(line, screenshots_dir)
        if line =~/^!GRAPHVIZ (\S+) (.*)$/
          self.new($1, $2, screenshots_dir)
        else
          nil
        end
      end

      attr_reader :filename, :dot_file, :screenshots_dir, :description

      def initialize(filename,description, screenshots_dir)
        @filename = Pathname(filename + ".png")
        @dot_file = Pathname(filename + ".dot")
        @description = description
        @screenshots_dir = Pathname(screenshots_dir)
        @append_to_dot_commands = []
        @continue = true
      end

      def execute
        []
      end

      def continue?
        @continue
      end

      def append(line)
        if line =~ /^!END GRAPHVIZ *$/
          @continue = false
          [
            Commands::MethodCall.new(
              FileUtils,
              :rm_rf,
              @screenshots_dir / @dot_file
            )
          ] + @append_to_dot_commands + [
            Commands::Sh.new(
              command: "dot -Tpng #{@screenshots_dir / @dot_file} -o#{@screenshots_dir / @filename}",
              expecting_success: true,
              show_output: false),
            Commands::PutsToFileIO.new(
              "<a href=\"images/#{@filename}\"><img src=\"images/#{@filename}\" alt=\"#{@description}\"><br><small>Click to embiggen</small></a>"
            )
          ]
        else
          @append_to_dot_commands << Commands::AppendToFileName.new(@screenshots_dir / @dot_file, line)
          []
        end
      end
    end
  end
end
