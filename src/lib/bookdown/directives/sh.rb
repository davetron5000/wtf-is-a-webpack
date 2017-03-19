require 'stringio'
module Bookdown
  module Directives
    class Sh
      def self.recognize(line)
        if line =~ /^!SH({.*})? (.*)$/
          command,options = if $2.nil?
                              [$1,[]]
                            else
                              [$2,$1.to_s.gsub(/[{}]/,'').split(/,/)]
                            end
          self.new(command,options)
        else
          nil
        end
      end

      def initialize(command,options)
        @command = command
        @options = options
      end

      def execute(&block)
        io = StringIO.new
        puts "Executing #{@command}"
        io.puts "```"
        stdout,stderr,status = Open3.capture3(@command)
        good = if @options.include?("nonzero")
                     !status.success?
                   else
                     status.success?
                   end
        if good
          if block.nil?
            io.puts "> #{@command}"
            io.puts stdout
            io.puts stderr
          else
            block.(@command,stdout,io)
          end
        else
          raise status.inspect + "\n" + stdout + "\n" + stderr
        end
        io.puts "```"
        [Commands::PutsToFileIO.new(io.string)]
      end
    end
  end
end
