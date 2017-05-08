require "spec_helper"
require "logger"
require "open3"
require "bookdown/sh_runner"

RSpec.describe Bookdown::ShRunner do
  describe "#run_command" do
    let(:logger) { instance_double(Logger) }
    let(:stdout) { "This is stdout" }
    let(:stderr) { "This is stderr" }
    let(:status) { instance_double(Process::Status, success?: true) }

    before do
      allow(logger).to receive(:info)
      allow(Open3).to receive(:capture3).and_return([stdout,stderr,status])
    end

    context "expecting success" do
      subject(:sh_runner) {
        described_class.new(
          command: "ls",
          expecting_success: true,
          logger: logger
        )
      }
      context "and command succeeds" do
        it "executes, returning stdout/stderr" do
          out,err = sh_runner.run_command
          expect(logger).to have_received(:info).with("Executing 'ls'")
          expect(out).to eq(stdout)
          expect(err).to eq(stderr)
        end
      end
      context "and command fails" do
        let(:status) { instance_double(Process::Status, success?: false) }
        it "raises" do
          expect {
            sh_runner.run_command
          }.to raise_error(RuntimeError,/#{stdout}.*#{stderr}/m)
          expect(logger).to have_received(:info).with("Executing 'ls'")
        end
      end
    end
    context "expecting failure" do
      subject(:sh_runner) {
        described_class.new(
          command: "ls",
          expecting_success: false,
          logger: logger
        )
      }

      context "and command fails" do
        let(:status) { instance_double(Process::Status, success?: false) }

        it "executes, returning stdout/stderr" do
          out,err = sh_runner.run_command
          expect(logger).to have_received(:info).with("Executing 'ls'")
          expect(out).to eq(stdout)
          expect(err).to eq(stderr)
        end
      end
      context "and command succeeds" do
        it "raises" do
          expect {
            sh_runner.run_command
          }.to raise_error(RuntimeError,/#{stdout}.*#{stderr}/m)
          expect(logger).to have_received(:info).with("Executing 'ls'")
        end
      end
    end
  end
end
