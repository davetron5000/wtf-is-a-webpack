require_relative "base_command"

class Bookdown::Directives::Commands::Sh < Bookdown::Directives::Commands::BaseCommand
  def initialize(command:, expecting_success: true)
    @command           = command
    @expecting_success = expecting_success
  end

  def execute(current_output_io,logger)
    logger.info "Executing #{@command}"
    current_output_io.puts "```"
    stdout,stderr,status = Open3.capture3(@command)
    command_did_what_was_expected = if @expecting_success
                                      status.success?
                                    else
                                      !status.success?
                                    end
    if command_did_what_was_expected
      current_output_io.puts "> #{@command}"
      current_output_io.puts stdout if stdout.strip != ""
      current_output_io.puts stderr if stderr.strip != ""
    else
      raise status.inspect + "\n" + stdout + "\n" + stderr
    end
    current_output_io.puts "```"
  end
end
