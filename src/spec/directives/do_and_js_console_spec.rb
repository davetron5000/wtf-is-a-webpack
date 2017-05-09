require "spec_helper"
require "bookdown/directives/do_and_js_console"
require "pathname"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"

RSpec.describe Bookdown::Directives::DoAndJsConsole do
  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize("!DO_AND_DUMP_CONSOLE blah.html", as: {
        html_file: "blah.html",
      })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
    end
  end
  describe "#append" do
    subject(:directive) { described_class.new("foo.html") }
    context "ending directive" do
      it "creates the executable with the captured source" do
        directive.append("source line 1")
        directive.append("source line 2")
        queue = directive.append("!END DO_AND_DUMP_CONSOLE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::MakeExecutableCommand,
          code: ["source line 1","source line 2"]
        )
      end
      it "runs PhantomJS to dump the console using the executable" do
        queue = directive.append("!END DO_AND_DUMP_CONSOLE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PhantomJS
        )
      end
    end
    context "more code" do
      it "returns nothing" do
        queue = directive.append("source line 1")
        expect(queue).to eq([])
      end
    end
  end
  describe "#execute" do
    it "returns no commands" do
      queue = described_class.new("foo.html").execute
      expect(queue).to eq([])
    end
  end
  describe "#continue" do
    subject(:directive) { described_class.new("foo.html") }
    context "when the end directive has been found" do
      it "returns false" do
        directive.append("!END DO_AND_DUMP_CONSOLE")
        expect(directive.continue?).to eq(false)
      end
    end
    context "when first created" do
      specify { expect(directive.continue?).to eq(true) }
    end
    context "when lines have been parsed that are not the end directive" do
      it "returns true" do
        directive.append("foobar")
        expect(directive.continue?).to eq(true)
      end
    end
  end
end
