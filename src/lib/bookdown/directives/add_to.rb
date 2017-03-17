require 'pathname'
module Bookdown
  module Directives
    class AddTo
      class Command
        attr_reader :object, :method, :argument
        def initialize(object,method,argument)
          @object = object
          @method = method
          @argument = argument
        end

        def execute(_)
          @object.send(method,argument)
        end
      end

      class PutsToFileIOCommand < Command
        def initialize(string)
          super(nil,nil,string)
        end
        def execute(file)
          file.puts(argument)
        end
      end

      class AppendToFileNameCommand < Command
        def initialize(filename,string)
          super(nil,nil,string)
          @filename = filename
        end
        def execute(_)
          File.open(@filename,"a") do |file|
            file.puts(argument)
          end
        end
      end

      def self.recognize(line)
        if line =~/^!ADD_TO({.*})? (.*)$/
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
      end

      def execute
        queue = []
        if @options.include?("replace")
          queue << Command.new($stdout, :puts, "Deleting \"#{@filename}\"")
          queue << Command.new(FileUtils,:rm_rf,@filename)
        end
        queue << Command.new($stdout,:puts,"Creating #{@filename.dirname}")
        queue << Command.new(FileUtils,:mkdir_p,@filename.dirname)
        queue << PutsToFileIOCommand.new("```#{language(@filename)}")
        queue
      end

      def append(line)
        queue = []
        queue << AppendToFileNameCommand.new(@filename,line)
        queue << PutsToFileIOCommand.new(line)
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
