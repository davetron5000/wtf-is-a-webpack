require 'tempfile'
require_relative 'js_console'
require_relative 'commands/base_command'

module Bookdown
  module Directives
    class DoAndJsConsole < JsConsole
      def self.recognize(line)
        if line =~ /^!DO_AND_DUMP_CONSOLE (.*)$/
          html = $1
          self.new(html)
        else
          nil
        end
      end

      def initialize(*args)
        super
        @continue = true
        @code = []
      end

      def append(line)
        if line =~ /^!END DO_AND_DUMP_CONSOLE *$/
          @continue = false
          make_executable = Commands::MakeExecutableCommand.new(@code,@js_exe)
          command = "phantomjs #{make_executable.generated_source.path} #{@html_file}"
          [ make_executable ] + console_commands(make_executable.generated_source.path)
        else
          @code << line
          []
        end
      end

      def execute
        []
      end

      def continue?
        @continue
      end
    end
  end
end
