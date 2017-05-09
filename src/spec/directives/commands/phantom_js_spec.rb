require "spec_helper"
require "logger"
require "stringio"
require "bookdown/sh_runner"
require "bookdown/directives/commands/phantom_js"

RSpec.describe Bookdown::Directives::Commands::PhantomJS do
  describe "#execute" do
    let(:logger)    { instance_double(Logger) }
    let(:io)        { StringIO.new }
    let(:sh_runner) { instance_double(Bookdown::ShRunner) }
    let(:stdout)    { "this is stdout" }
    let(:stderr)    { "this is stderr" }

    before do
      allow(Bookdown::ShRunner).to receive(:new).and_return(sh_runner)
      allow(sh_runner).to receive(:run_command).and_return([stdout,stderr])
    end

    context "showing output" do
      subject(:command) {
        described_class.new(
          script_file: "foo.js",
          args: [ "one", "two" ],
          show_output: true
        )
      }
      it "executes PhantomJS" do
        command.execute(io,logger)

        expect(Bookdown::ShRunner).to have_received(:new).with(
          command: "phantomjs foo.js one two",
          expecting_success: true,
          logger: logger
        )
      end
      it "outputs stderr and stdout in a fenced code block" do
        command.execute(io,logger)

        expect(io.string).to eq("```\nthis is stdout\nthis is stderr\n```\n")
      end
      context "no stderr" do
        let(:stdout)    { "this is stdout" }
        let(:stderr)    { "" }
        it "outputs stdout in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\nthis is stdout\n```\n")
        end
      end
      context "no stdout" do
        let(:stdout)    { "" }
        let(:stderr)    { "this is stderr" }
        it "outputs stderr in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\nthis is stderr\n```\n")
        end
      end
      context "no stdout nor stderr" do
        let(:stdout)    { "" }
        let(:stderr)    { "" }
        it "outputs nothing" do
          command.execute(io,logger)

          expect(io.string).to eq("")
        end
      end
    end
    context "not showing output" do
      subject(:command) {
        described_class.new(
          script_file: "foo.js",
          args: [ "one", "two" ],
          show_output: false
        )
      }
      it "executes PhantomJS" do
        command.execute(io,logger)

        expect(Bookdown::ShRunner).to have_received(:new).with(
          command: "phantomjs foo.js one two",
          expecting_success: true,
          logger: logger
        )
      end
      it "outputs nothign" do
        command.execute(io,logger)

        expect(io.string).to eq("")
      end
    end
  end
end
