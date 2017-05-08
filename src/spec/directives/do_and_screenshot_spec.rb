require "spec_helper"
require "bookdown/directives/do_and_screenshot"
require "pathname"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::DoAndScreenshot do
  subject(:directive) { described_class.new("this is a title", "foo.html","foo.png", 640, 480, "foo") }
  describe "::recognize" do
    context "a DO_AND_SCREENSHOT directive" do
      subject(:directive) {
        described_class.recognize("!DO_AND_SCREENSHOT \"this is a title\" blah.html","foo")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the title" do
        expect(directive.title).to eq("this is a title")
      end
      it "parses the filename" do
        expect(directive.html_file).to eq("blah.html")
      end
      it "passes the screenshots dir to the instance it created" do
        expect(directive.screenshots_dir).to eq("foo")
      end
    end
    context "another directive" do
      it "does not create a new #{described_class}" do
        directive = described_class.recognize("!EDIT_FILE blah.html","foo")
        expect(directive).to be_nil
      end
    end
  end
  describe "#append" do
    context "ending directive" do
      it "creates the executable with the captured source" do
        directive.append("source line 1")
        directive.append("source line 2")
        queue = directive.append("!END DO_AND_SCREENSHOT")
        expect(queue).to have_command(
          described_class::MakeExecutableCommand,
          code: ["source line 1","source line 2"]
        )
      end
      it "runs PhantomJS to dump the console using the executable" do
        queue = directive.append("!END DO_AND_SCREENSHOT")
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
      queue = directive.execute
      expect(queue).to eq([])
    end
  end
  describe "#continue" do
    context "when the end directive has been found" do
      it "returns false" do
        directive.append("!END DO_AND_SCREENSHOT")
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
