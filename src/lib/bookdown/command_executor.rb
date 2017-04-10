module Bookdown
  class CommandExecutor
    def initialize(logger: )
      @logger = logger
    end
    def execute_all(commands,file)
      commands.each do |command|
        command.execute(file,@logger)
      end
    end
  end
end
