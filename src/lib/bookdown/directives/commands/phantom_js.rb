require_relative "base_command"
require_relative "../../sh_runner"

class Bookdown::Directives::Commands::PhantomJS < Bookdown::Directives::Commands::BaseCommand
  def initialize(script_file: , args: , show_output: false)
    @script_file = script_file
    @args        = args
    @show_output = show_output
  end

  def execute(current_output_io,logger)
    sh_runner = Bookdown::ShRunner.new(command: "phantomjs #{@script_file} #{@args.join(' ')}",
                                       expecting_success: true,
                                       logger: logger)
    stdout,stderr = sh_runner.run_command
    if @show_output
      current_output_io.puts "```"
      current_output_io.puts stdout if stdout.strip != ""
      current_output_io.puts stderr if stderr.strip != ""
      current_output_io.puts "```"
    end
  end
end
