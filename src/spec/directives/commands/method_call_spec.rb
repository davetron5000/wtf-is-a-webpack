require "spec_helper"
require "logger"
require "bookdown/directives/commands/method_call"

class MyObject
  def doit(string)
  end
end
RSpec.describe Bookdown::Directives::Commands::MethodCall do
  describe "#execute" do
    let(:logger) { instance_double(Logger) }
    let(:io)     { instance_double(IO) }

    before do
      allow(logger).to receive(:info)
    end

    context "when puts to stdout" do
      subject(:command) { described_class.new($stdout,:puts,"Hello") }

      it "logs to the logger instead" do
        command.execute(io,logger)
        expect(logger).to have_received(:info).with("Hello")
      end
    end
    context "normal method call" do

      let(:object) { MyObject.new }

      subject(:command) { described_class.new(object,:doit,"Hello") }

      before do
        allow(object).to receive(:doit).with("Hello")
      end

      it "calls the method with the argument" do
        command.execute(io,logger)
        expect(object).to have_received(:doit).with("Hello")
      end
    end
  end
end
