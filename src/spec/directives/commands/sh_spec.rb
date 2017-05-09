require "spec_helper"
require "logger"
require "stringio"
require "bookdown/directives/commands/sh"
require "bookdown/sh_runner"

RSpec.describe Bookdown::Directives::Commands::Sh do
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

    context "expecting success" do
      subject(:command) {
        described_class.new(
          command: "ls -ltr",
          expecting_success: true
        )
      }
      it "executes the command" do
        command.execute(io,logger)

        expect(Bookdown::ShRunner).to have_received(:new).with(
          command: "ls -ltr",
          expecting_success: true,
          logger: logger
        )
      end
      it "outputs the command, stderr, and stdout in a fenced code block" do
        command.execute(io,logger)

        expect(io.string).to eq("```\n> ls -ltr\nthis is stdout\nthis is stderr\n```\n")
      end
      context "no stderr" do
        let(:stdout)    { "this is stdout" }
        let(:stderr)    { "" }
        it "outputs the command and stdout in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\nthis is stdout\n```\n")
        end
      end
      context "no stdout" do
        let(:stdout)    { "" }
        let(:stderr)    { "this is stderr" }
        it "outputs the command stderr in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\nthis is stderr\n```\n")
        end
      end
      context "no stdout nor stderr" do
        let(:stdout)    { "" }
        let(:stderr)    { "" }
        it "outputs the command" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\n```\n")
        end
      end
    end
    context "expecting failure" do
      subject(:command) {
        described_class.new(
          command: "ls -ltr",
          expecting_success: false
        )
      }
      it "executes the command" do
        command.execute(io,logger)

        expect(Bookdown::ShRunner).to have_received(:new).with(
          command: "ls -ltr",
          expecting_success: false,
          logger: logger
        )
      end
      it "outputs the command, stderr, and stdout in a fenced code block" do
        command.execute(io,logger)

        expect(io.string).to eq("```\n> ls -ltr\nthis is stdout\nthis is stderr\n```\n")
      end
      context "no stderr" do
        let(:stdout)    { "this is stdout" }
        let(:stderr)    { "" }
        it "outputs the command and stdout in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\nthis is stdout\n```\n")
        end
      end
      context "no stdout" do
        let(:stdout)    { "" }
        let(:stderr)    { "this is stderr" }
        it "outputs the command stderr in a fenced code block" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\nthis is stderr\n```\n")
        end
      end
      context "no stdout nor stderr" do
        let(:stdout)    { "" }
        let(:stderr)    { "" }
        it "outputs the command" do
          command.execute(io,logger)

          expect(io.string).to eq("```\n> ls -ltr\n```\n")
        end
      end
    end
  end
end
