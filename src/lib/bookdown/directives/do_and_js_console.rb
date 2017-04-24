require 'tempfile'
require_relative 'js_console'

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

      class MakeExecutableCommand < Commands::BaseCommand
        attr_reader :generated_source
        def initialize(code,source)
          @code = code
          @source = source
          @generated_source = Tempfile.new(["do_and_dump_console",".js"])
        end

        def execute(_current_output_io,logger)
          File.open(@source).readlines.each do |line|
            if line =~ /::CUSTOM_CODE::/
              @code.each do |code_line|
                logger.info "Adding #{code_line} to #{@generated_source.path}"
                @generated_source.puts code_line
              end
            else
              @generated_source.puts line
            end
          end
          @generated_source.close
          require 'fileutils'
          FileUtils.cp @generated_source.path,"/tmp/blah.js"
        end
      end

      def append(line)
        if line =~ /^!END DO_AND_DUMP_CONSOLE *$/
          @continue = false
          make_executable = MakeExecutableCommand.new(@code,@js_exe)
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
