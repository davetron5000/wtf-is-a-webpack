require_relative "base_command"
class Bookdown::Directives::Commands::WarnIfFileExists < Bookdown::Directives::Commands::BaseCommand
  def initialize(filename)
    @filename = filename
  end

  def execute(_current_output_io,logger)
    if File.exist?(@filename)
      logger.warn("File #{@filename} already exists.  Consider using EDIT_FILE")
    end
  end
end

