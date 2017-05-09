require "spec_helper"
require "bookdown/directives/sh"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::Sh do
  describe "::recognize" do
    context "an SH directive with no options" do
      subject(:directive) {
        described_class.recognize("!SH ls -ltr")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the command" do
        expect(directive.command).to eq("ls -ltr")
      end
      it "defaults options to []" do
        expect(directive.options).to eq([])
      end
    end
    context "an SH directive with options" do
      subject(:directive) {
        described_class.recognize("!SH{foo,bar} ls -ltr")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the command" do
        expect(directive.command).to eq("ls -ltr")
      end
      it "parses the options" do
        expect(directive.options).to eq(["foo","bar"])
      end
    end
    context "another directive" do
      it "does not create a new #{described_class}" do
        directive = described_class.recognize("!EDIT_FILE blah.html")
        expect(directive).to be_nil
      end
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
