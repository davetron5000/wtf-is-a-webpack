require "json"
require_relative "commands/method_call"
require_relative "commands/merge_package_json"
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
          parsed_additions = JSON.parse(@package_json)
          queue << Commands::MethodCall.new($stdout,:puts,"Inserting into package.json:\n#{@package_json}")
          queue << Commands::MergePackageJSON.new(parsed_additions)
          queue << Commands::PutsToFileIO.new("```json")
          queue << Commands::PutsToFileIO.new(JSON.pretty_generate(parsed_additions))
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
