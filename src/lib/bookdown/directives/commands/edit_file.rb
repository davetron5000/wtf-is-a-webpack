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
    existing_file_lines = File.open(@file_to_edit).readlines
    File.open(@file_to_edit,"w") do |file|
      io = MultiplexedIO.new(file,current_output_io)
      existing_file_lines.each do |line|

        if edit_instruction = matching_instruction(line,logger)
          edit_code(io,line,edit_instruction,logger)
        elsif comment_from_previous_run?(line)
          logger.info("Omitting comment from previous run: '#{line}'")
        else
          io.puts line
        end

      end
    end

    error_on_unused_instructions!
  end

private

  def edit_code(io,line,edit_instruction,logger)
    if edit_instruction["insert_before"]
      insert_code(io,edit_instruction["insert_before"],logger)
      io.puts line
    elsif edit_instruction["insert_after"]
      io.puts line
      insert_code(io,edit_instruction["insert_after"],logger)
    elsif edit_instruction["replace_with"]
      insert_code(io,edit_instruction["replace_with"],logger)
    else
      raise "Matched '#{line.chomp}', but don't understand instruction '#{edit_instruction.keys[1]}'"
    end
  end

  def insert_code(io,code,logger)
    io.puts @start_comment + " start new code " + @end_comment
    code.each do |new_line|
      logger.info("Inserting '#{new_line}'")
      io.puts new_line
    end
    io.puts @start_comment + " end new code " + @end_comment
  end

  def matching_instruction(line,logger)
    @editing_instructions.detect { |instruction|
      regexp = Regexp.compile("^" + Regexp.escape(instruction.fetch("match")))
      if regexp.match(line)
        logger.debug("Matched '#{line.chomp}' for #{instruction.inspect}")
        instruction
      end
    }.tap { |matched_instruction|
      @editing_instructions.delete(matched_instruction)
    }
  end

  def comment_from_previous_run?(line)
    line =~ /^\s*#{Regexp.escape(@start_comment)}.* new code\s+#{Regexp.escape(@end_comment)}$/
  end

  def error_on_unused_instructions!
    unless @editing_instructions.empty?
      raise "Didn't find a match for " +
        @editing_instructions.map { |_| "'" + _["match"] + "'" }.join(", ") +
        "  File was:\n#{File.read(@file_to_edit)}\n\n"
    end
  end
end
