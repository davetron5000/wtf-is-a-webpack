require "spec_helper"
require "logger"
require "bookdown/directives/commands/warn_if_file_exists"

RSpec.describe Bookdown::Directives::Commands::WarnIfFileExists do
  describe "#execute" do
    let(:logger) { instance_double(Logger) }
    let(:io)     { instance_double(IO) }

    subject(:command) { described_class.new("foo.html") }

    before do
      allow(logger).to receive(:warn)
    end
    context "when file exists" do
      before do
        allow(File).to receive(:exist?).and_return(true)
        command.execute(io,logger)
      end

      specify { expect(logger).to have_received(:warn).with("File foo.html already exists.  Consider using EDIT_FILE") }
    end
    context "when file does not exist" do
      before do
        allow(File).to receive(:exist?).and_return(false)
        command.execute(io,logger)
      end
      specify { expect(logger).not_to have_received(:warn) }
    end
  end
end
