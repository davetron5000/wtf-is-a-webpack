require_relative "base_command"
class Bookdown::Directives::Commands::EditFile < Bookdown::Directives::Commands::BaseCommand
  attr_reader :editing_instructions
  def initialize(file_to_edit,start_comment,end_comment,editing_instructions)
    @file_to_edit         = file_to_edit
    @start_comment        = start_comment
    @end_comment          = end_comment
    @editing_instructions = editing_instructions
  end

  class MultiplexedIO
    def initialize(*ios)
      @ios = ios
    end

    def puts(string)
      @ios.each do |io|
        io.puts string
      end
    end
  end

  def execute(current_output_io,logger)
    existing_file = File.open(@file_to_edit).readlines
    File.open(@file_to_edit,"w") do |file|
      io = MultiplexedIO.new(file,current_output_io)
      existing_file.each do |line|
        edit = @editing_instructions.detect { |instruction|
          regexp = Regexp.compile("^" + Regexp.escape(instruction.fetch("match")))
          if regexp.match(line)
            logger.debug("Matched '#{line.chomp}' for #{instruction.inspect}")
            instruction
          end
        }
        if edit
          @editing_instructions.delete(edit)
          if edit["insert_before"]
            io.puts @start_comment + " start new code " + @end_comment
            edit["insert_before"].each do |new_line|
              logger.info("Inserting '#{new_line}'")
              io.puts new_line
            end
            io.puts @start_comment + " end new code " + @end_comment
            io.puts line
          elsif edit["insert_after"]
            io.puts line
            io.puts @start_comment + " start new code " + @end_comment
            edit["insert_after"].each do |new_line|
              logger.info("Inserting '#{new_line}'")
              io.puts new_line
            end
            io.puts @start_comment + " end new code " + @end_comment
          elsif edit["replace_with"]
            io.puts @start_comment + " start new code " + @end_comment
            edit["replace_with"].each do |new_line|
              logger.info("Inserting '#{new_line}'")
              io.puts new_line
            end
            io.puts @start_comment + " end new code " + @end_comment
          else
            raise "Can't figure out what to do with #{edit.inspect}"
          end
        elsif line =~ /^\s*#{Regexp.escape(@start_comment)}.* new code\s+#{Regexp.escape(@end_comment)}$/
          logger.info("Omitting comment from previous run: '#{line}'")
        else
          io.puts line
        end
      end
    end
    unless @editing_instructions.empty?
      raise "Certain instructions could not be applied: #{@editing_instructions.inspect}.  File was: \n#{File.read(@file_to_edit)}\n\n"
    end
  end
end
