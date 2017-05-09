require "tempfile"
require_relative "screenshot"
require_relative "commands/make_executable_command"

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

      def append(line)
        if line =~ /^!END DO_AND_SCREENSHOT *$/
          @continue = false
          make_executable = Commands::MakeExecutableCommand.new(@code,@js_exe)
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
