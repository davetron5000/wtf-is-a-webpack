require_relative "base_command"
require_relative "../../sh_runner"

class Bookdown::Directives::Commands::PhantomJS < Bookdown::Directives::Commands::BaseCommand
  attr_reader :args
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
    stdout = stdout.to_s.strip
    stderr = stderr.to_s.strip
    @show_output = @show_output && (stdout != "" || stderr != "")
    if @show_output
      current_output_io.puts "```"
      current_output_io.puts stdout if stdout != ""
      current_output_io.puts stderr if stderr != ""
      current_output_io.puts "```"
    end
  end
end
