require "pathname"
module Bookdown
  module Directives
    class JsConsole
      def self.recognize(line)
        if line =~ /^!DUMP_CONSOLE (.*)$/
          html_file = $1
          self.new(html_file)
        else
          nil
        end
      end

      def initialize(html_file)
        @html_file = html_file
        @js_exe = Pathname("../src/dump_console.js").expand_path
        raise "Cannot find #{@js_exe}" unless @js_exe.exist?
      end

      def execute
        [ Commands::Sh.new(command: "phantomjs #{@js_exe} #{@html_file}") ]
      end
    end
  end
end
