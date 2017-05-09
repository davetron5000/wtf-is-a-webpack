require "spec_helper"
require "bookdown/directives/sh"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"
require_relative "../support/matchers/be_single_line_directive"

RSpec.describe Bookdown::Directives::Sh do

  specify { expect(described_class.new("ls",[])).to be_single_line_directive }

  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize("!SH ls -ltr", as: {
        command: "ls -ltr",
        options: []
      })
    end
    it "can parse a command with options" do
      expect(described_class).to recognize("!SH{foo,bar} ls -ltr", as: {
        command: "ls -ltr",
        options: ["foo","bar"]
      })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
    end
  end
  describe "#execute" do
    context "with the nonzero option" do
      subject(:directive) { described_class.new("ls",[ "nonzero" ]) }
      it "executes the command, exepecting failure" do
        expect(directive.execute).to have_command(
          Bookdown::Directives::Commands::Sh,
          command: "ls",
          expecting_success: false
        )
      end
    end
    context "without the nonzero options" do
      subject(:directive) { described_class.new("ls",[ ]) }
      it "executes the command, exepecting success" do
        expect(directive.execute).to have_command(
          Bookdown::Directives::Commands::Sh,
          command: "ls",
          expecting_success: true
        )
      end
    end
  end
end
