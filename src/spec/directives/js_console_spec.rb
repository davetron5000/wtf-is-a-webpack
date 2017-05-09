require "spec_helper"
require "bookdown/directives/js_console"
require "pathname"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"

RSpec.describe Bookdown::Directives::JsConsole do
  describe "::recognize" do
    it "can parse a command" do
      expect(described_class).to recognize("!DUMP_CONSOLE blah.html", as: {
        html_file: "blah.html",
      })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
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
