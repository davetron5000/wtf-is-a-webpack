require_relative "screenshot"
require_relative "commands/phantom_js"
require_relative "commands/puts_to_file_io"

module Bookdown
  module Directives
    class Screenshot
      def self.recognize(line,screenshots_dir)
        if line =~ /^!SCREENSHOT (\"[^"]+\") (.*)$/
          title = $1
          html,screenshot_image_name,width,height = $2.split(/\s+/)
          self.new(title,html,screenshot_image_name,width,height,screenshots_dir)
        else
          nil
        end
      end

      attr_reader :html_file, :title, :screenshots_dir
      def initialize(title,html_file, screenshot_image_name, width, height, screenshots_dir)
        @title                 = title
        @html_file             = html_file
        @screenshot_image_name = screenshot_image_name
        @width                 = width
        @height                = height
        @screenshots_dir       = screenshots_dir
        @js_exe                = Pathname("../src/screenshot.js").expand_path
      end

      def execute
        screenshot_commands(@js_exe)
      end

    private

      def screenshot_commands(js_exe)
        [
          Commands::PhantomJS.new(script_file: js_exe, args: [@html_file, "#{@screenshots_dir}/#{@screenshot_image_name}",@width,@height]),
          Commands::PutsToFileIO.new("![#{@title}](images/#{@screenshot_image_name})"),
        ]
      end

    end
  end
end
