require "spec_helper"
require "bookdown/command_executor"
require "bookdown/directives/commands/base_command"
require "logger"

RSpec.describe Bookdown::CommandExecutor do

  let(:logger) { instance_double(Logger) }

  subject(:command_exeutor) { described_class.new(logger: logger) }
  describe "#execute_all" do
    it "executes all commands given to it" do
      command1 = instance_double(Bookdown::Directives::Commands::BaseCommand)
      command2 = instance_double(Bookdown::Directives::Commands::BaseCommand)
      file     = instance_double(File)

      allow(command1).to receive(:execute)
      allow(command2).to receive(:execute)

      command_exeutor.execute_all([command1,command2],file)

      expect(command1).to have_received(:execute).with(file,logger)
      expect(command2).to have_received(:execute).with(file,logger)
    end
  end
end
