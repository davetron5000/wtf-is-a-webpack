require_relative "base_command"
class Bookdown::Directives::Commands::AppendToFileName < Bookdown::Directives::Commands::BaseCommand
  def initialize(filename,string)
    @filename = filename
    @string = string
  end
  def execute(_current_output_io,_logger)
    File.open(@filename,"a") do |file|
      file.puts(@string)
    end
  end
end
