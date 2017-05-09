require "spec_helper"
require "bookdown/directives/do_and_screenshot"
require "pathname"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"

RSpec.describe Bookdown::Directives::DoAndScreenshot do
  subject(:directive) { described_class.new("this is a title", "foo.html","foo.png", "640", "480", "foo") }
  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize(
        "!DO_AND_SCREENSHOT \"this is a title\" blah.html blah.png","foo",
        as: {
          title: "this is a title",
          html_file: "blah.html",
          screenshot_image_name: "blah.png",
          width: nil,
          height: nil,
          screenshots_dir: "foo"
        })
    end
    it "can parse a command with a width" do
      expect(described_class).to recognize(
        "!DO_AND_SCREENSHOT \"this is a title\" blah.html blah.png 640","foo",
        as: {
          title: "this is a title",
          html_file: "blah.html",
          screenshot_image_name: "blah.png",
          width: "640",
          height: nil,
          screenshots_dir: "foo"
        })
    end
    it "can parse a command with a width and height" do
      expect(described_class).to recognize(
        "!DO_AND_SCREENSHOT \"this is a title\" blah.html blah.png 640 480","foo",
        as: {
          title: "this is a title",
          html_file: "blah.html",
          screenshot_image_name: "blah.png",
          width: "640",
          height: "480",
          screenshots_dir: "foo"
        })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
    end
  end
  describe "#append" do
    context "ending directive" do
      it "creates the executable with the captured source" do
        directive.append("source line 1")
        directive.append("source line 2")
        queue = directive.append("!END DO_AND_SCREENSHOT")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::MakeExecutableCommand,
          code: ["source line 1","source line 2"]
        )
      end
      it "runs PhantomJS to dump the console using the executable" do
        queue = directive.append("!END DO_AND_SCREENSHOT")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PhantomJS,
          args: ["foo.html", "foo/foo.png","640","480"]
        )
      end
      it "outputs an image tag to the file" do
        queue = directive.append("!END DO_AND_SCREENSHOT")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "![this is a title](images/foo.png)"
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
