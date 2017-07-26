require_relative "base_command"
require_relative "../../sh_runner"

class Bookdown::Directives::Commands::Sh < Bookdown::Directives::Commands::BaseCommand
  attr_reader :command, :expecting_success, :show_output
  def initialize(command:, expecting_success: true, show_output: true)
    @command           = command
    @expecting_success = expecting_success
    @show_output       = show_output
  end

  def execute(current_output_io,logger)
    sh_runner = Bookdown::ShRunner.new(command: @command, expecting_success: @expecting_success, logger: logger)
    stdout,stderr = sh_runner.run_command
    stdout = stdout.strip.chomp
    stderr = stderr.strip.chomp
    if @show_output
      total_output = if stdout == ""
                       stderr
                     elsif stderr == ""
                       stdout
                     else
                       stdout + "\n" + stderr
                     end
      split_output = total_output.split(/\n/).size > 9

      current_output_io.puts "```shell"
      current_output_io.puts "> #{@command}"
      if split_output
        current_output_io.puts "```"
        current_output_io.puts "```stdout"
        current_output_io.puts total_output
        current_output_io.puts "```"
      else
        current_output_io.puts total_output if total_output.size > 0
        current_output_io.puts "```"
      end
    end
  end
end
