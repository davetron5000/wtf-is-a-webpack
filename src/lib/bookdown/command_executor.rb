module Bookdown
  class CommandExecutor
    def execute_all(commands,file)
      commands.each do |command|
        command.execute(file)
      end
    end
  end
end
