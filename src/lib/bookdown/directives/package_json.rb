require "json"
require_relative "commands/method_call"
require_relative "commands/write_file"
require_relative "commands/puts_to_file_io"

module Bookdown
  module Directives
    class PackageJson
      def self.recognize(line)
        if line =~/^!PACKAGE_JSON *$/
          self.new
        else
          nil
        end
      end

      def initialize
        @package_json = ""
        @continue = true
      end
      def execute
        []
      end

      def continue?
        @continue
      end

      def append(line)
        if line =~ /^!END PACKAGE_JSON *$/
          queue = []
          @continue = false
          existing_package_json = JSON.parse(File.read("package.json"))
          queue << Commands::MethodCall.new($stdout,:puts,"Inserting into package.json:\n#{@package_json}")
          parsed_additions = JSON.parse(@package_json)
          new_package_json = JSON.pretty_generate(existing_package_json.merge(parsed_additions))
          queue << Commands::WriteFile.new("package.json",new_package_json)
          queue << Commands::PutsToFileIO.new("```json")
          queue << Commands::PutsToFileIO.new(new_package_json)
          queue << Commands::PutsToFileIO.new("```")
          queue
        else
          @package_json << line
          []
        end
      end
    end
  end
end
