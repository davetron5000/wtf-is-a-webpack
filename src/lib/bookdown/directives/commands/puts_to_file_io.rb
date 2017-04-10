require_relative "base_command"
class Bookdown::Directives::Commands::PutsToFileIO < Bookdown::Directives::Commands::BaseCommand
  def initialize(string)
    @string = string
  end
  def execute(current_output_io,_logger)
    current_output_io.puts(@string)
  end
end
