require 'pathname'
require_relative "../language"
require_relative "commands/method_call"
require_relative "commands/puts_to_file_io"
require_relative "commands/append_to_file_name"
module Bookdown
  module Directives
    class CreateFile
      def self.recognize(line)
        if line =~/^!CREATE_FILE({.*})? (.*)$/
          filename,options = if $2.nil?
                                    [$1,[]]
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

      class WarnIfFileExists < Commands::BaseCommand
        def initialize(filename)
          @filename = filename
        end

        def execute(_current_output_io,logger)
          if File.exist?(@filename)
            logger.warn("File #{@filename} already exists.  Consider using EDIT_FILE")
          end
        end
      end

      def execute
        queue = []
        queue << WarnIfFileExists.new(@filename)
        queue << Commands::MethodCall.new($stdout, :puts, "Deleting \"#{@filename}\"")
        queue << Commands::MethodCall.new(FileUtils,:rm_rf,@filename)
        queue << Commands::MethodCall.new($stdout,:puts,"Creating #{@filename.dirname}")
        queue << Commands::MethodCall.new(FileUtils,:mkdir_p,@filename.dirname)
        queue << Commands::PutsToFileIO.new("```#{Bookdown::Language.new(@filename)}")
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
    end
  end
end
