require "tempfile"
require "json"
require "pathname"
require_relative "../language"
require_relative "commands/base_command"
require_relative "commands/method_call"
require_relative "commands/puts_to_file_io"
require_relative "commands/edit_file"

module Bookdown
  module Directives
    class EditFile
      def self.recognize(line)
        if line =~ /^!EDIT_FILE (\S+)\s+(\S+)$/ ||
           line =~ /^!EDIT_FILE (\S+)\s+(\S+)\s+(\S+)$/
          filename = $1
          start_comment = $2
          end_comment = $3
          self.new(filename,start_comment,end_comment)
        elsif line =~ /^!EDIT_FILE (.*)/
          raise "EDIT_FILE requires two or three args: file, start_comment, optional end comment"
        else
          nil
        end
      end

      attr_reader :filename, :start_comment, :end_comment

      def initialize(filename,start_comment,end_comment)
        @filename      = Pathname(filename)
        @start_comment = start_comment
        @end_comment   = end_comment
        @continue      = true
        @json          = "["
      end

      def append(line)
        if line =~ /^!END EDIT_FILE *$/
          @json << "]"
          instructions = JSON.parse(@json)
          @continue = false
          [
            Commands::MethodCall.new($stdout,:puts,"Editing #{@filename}"),
            Commands::PutsToFileIO.new("```#{Bookdown::Language.new(@filename)}"),
            Commands::EditFile.new(@filename,@start_comment,@end_comment,instructions),
            Commands::PutsToFileIO.new("```"),
          ]
        else
          @json << line
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
