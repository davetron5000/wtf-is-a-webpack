require 'pathname'
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

      def execute
        queue = []
        queue << Commands::MethodCall.new($stdout, :puts, "Deleting \"#{@filename}\"")
        queue << Commands::MethodCall.new(FileUtils,:rm_rf,@filename)
        queue << Commands::MethodCall.new($stdout,:puts,"Creating #{@filename.dirname}")
        queue << Commands::MethodCall.new(FileUtils,:mkdir_p,@filename.dirname)
        queue << Commands::PutsToFileIO.new("```#{language(@filename)}")
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

      def language(filename)
        if filename.extname == ".js"
          "javascript"
        elsif filename.extname == ".html"
          "html"
        else
          raise "Can't determine language for #{filename}"
        end
      end
    end
  end
end
