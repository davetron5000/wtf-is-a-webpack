require "spec_helper"
require "bookdown/directives/do_and_js_console"
require "pathname"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::DoAndJsConsole do
  describe "::recognize" do
    context "a DO_AND_DUMP_CONSOLE directive" do
      subject(:directive) {
        described_class.recognize("!DO_AND_DUMP_CONSOLE blah.html")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename" do
        expect(directive.html_file).to eq("blah.html")
      end
    end
    context "another directive" do
      it "does not create a new #{described_class}" do
        directive = described_class.recognize("!EDIT_FILE blah.html")
        expect(directive).to be_nil
      end
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
          described_class::MakeExecutableCommand,
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
