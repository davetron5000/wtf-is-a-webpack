require "tempfile"
require_relative "screenshot"

module Bookdown
  module Directives
    class DoAndScreenshot < Screenshot
      def self.recognize(line,screenshots_dir)
        if line =~ /^!DO_AND_SCREENSHOT (\"[^"]+\") (.*)$/
          title = $1
          html,screenshot_image_name,width,height = $2.split(/\s+/)

          title = title.gsub(/^\"/,'').gsub(/\"$/,'')
          self.new(title,html,screenshot_image_name,width,height,screenshots_dir)
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
        attr_reader :generated_source, :code
        def initialize(code,source)
          @code = code
          @source = source
          @generated_source = Tempfile.new(["do_and_screenshot",".js"])
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
        end
      end

      def append(line)
        if line =~ /^!END DO_AND_SCREENSHOT *$/
          @continue = false
          make_executable = MakeExecutableCommand.new(@code,@js_exe)
          command = "phantomjs #{make_executable.generated_source.path} #{@html_file} #{@screenshots_dir}/#{@screenshot_image_name} #{@width} #{@height}"
          [ make_executable ] + screenshot_commands(make_executable.generated_source.path)
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
