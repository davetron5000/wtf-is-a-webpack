require 'pathname'
require_relative "../language"
require_relative "commands/method_call"
require_relative "commands/puts_to_file_io"
require_relative "commands/append_to_file_name"
require_relative "commands/warn_if_file_exists"

module Bookdown
  module Directives
    class CreateFile
      def self.recognize(line)
        if line =~/^!CREATE_FILE({.*})? (.*)$/
          filename,options = if $1.nil?
                               [$2,[]]
                             else
                               [$2,$1.to_s.gsub(/[{}]/,'').split(/,/)]
                             end
          self.new(filename,options)
        else
          nil
        end
      end

      attr_reader :filename, :options

      def initialize(filename,options)
        @filename = Pathname(filename)
        @options = options
        @continue = true
      end

      def execute
        queue = []
        queue << Commands::WarnIfFileExists.new(@filename)
        queue << Commands::MethodCall.new($stdout, :puts, "Deleting \"#{@filename}\"")
        queue << Commands::MethodCall.new(FileUtils,:rm_rf,@filename)
        queue << Commands::MethodCall.new($stdout,:puts,"Creating #{@filename.dirname}")
        queue << Commands::MethodCall.new(FileUtils,:mkdir_p,@filename.dirname)
        queue << Commands::PutsToFileIO.new("```#{language}")
        queue
      end

      def continue?
        @continue
      end

      def append(line)
        queue = []
        if line =~ /^!END CREATE_FILE *$/
          @continue = false
          queue << Commands::PutsToFileIO.new("```")
        else
          queue << Commands::AppendToFileName.new(@filename,line)
          queue << Commands::PutsToFileIO.new(line)
        end
        queue
      end

    private

      def language
        language_override = @options.detect { |_| _ =~/^language=/ }
        if language_override
          language_override.gsub(/^language=/,'')
        else
          Bookdown::Language.new(@filename)
        end
      end
    end
  end
end
