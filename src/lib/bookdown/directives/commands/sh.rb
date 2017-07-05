require_relative "base_command"
require_relative "../../sh_runner"

class Bookdown::Directives::Commands::Sh < Bookdown::Directives::Commands::BaseCommand
  attr_reader :command, :expecting_success, :show_output
  def initialize(command:, expecting_success: true, show_output: true)
    @command           = command
    @expecting_success = expecting_success
    @show_output       = show_output
    warn "missing tests"
  end

  def execute(current_output_io,logger)
    sh_runner = Bookdown::ShRunner.new(command: @command, expecting_success: @expecting_success, logger: logger)
    stdout,stderr = sh_runner.run_command
    if @show_output
      current_output_io.puts "```"
      current_output_io.puts "> #{@command}"
      current_output_io.puts stdout if stdout.strip != ""
      current_output_io.puts stderr if stderr.strip != ""
      current_output_io.puts "```"
    end
  end
end
