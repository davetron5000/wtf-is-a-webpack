require_relative "single_line_directive"
require_relative "commands/sh"

module Bookdown
  module Directives
    class Sh
      include SingleLineDirective

      def self.recognize(line)
        if line =~ /^!SH({.*})? (.*)$/
          command,options = if $1.nil?
                              [$2,[]]
                            else
                              [$2,$1.to_s.gsub(/[{}]/,'').split(/,/)]
                            end
          self.new(command,options)
        else
          nil
        end
      end

      attr_reader :command, :options
      def initialize(command,options)
        @command = command
        @options = options
      end

      def execute
        [ Commands::Sh.new(command: @command, expecting_success: !@options.include?("nonzero")) ]
      end
    end
  end
end
