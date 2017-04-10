require_relative "base_command"

class Bookdown::Directives::Commands::MethodCall < Bookdown::Directives::Commands::BaseCommand
  attr_reader :object, :method, :argument
  def initialize(object,method,argument)
    @object   = object
    @method   = method
    @argument = argument
  end

  def execute(_current_output_io,logger)
    if @object == $stdout && method == :puts
      logger.info(@argument)
    else
      @object.send(method,argument)
    end
  end
end
