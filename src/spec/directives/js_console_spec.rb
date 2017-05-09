require "spec_helper"
require "bookdown/directives/js_console"
require "pathname"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::JsConsole do
  describe "::recognize" do
    context "a DUMP_CONSOLE directive" do
      subject(:directive) {
        described_class.recognize("!DUMP_CONSOLE blah.html")
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
  describe "#execute" do
    it "runs PhantomJS to dump the console using the executable" do
      queue = described_class.new("foo.html").execute
      expect(queue).to have_command(
        Bookdown::Directives::Commands::PhantomJS,
        args: [ "foo.html" ]
      )
    end
  end
end
