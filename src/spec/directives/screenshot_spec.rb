require "spec_helper"
require "bookdown/directives/screenshot"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"
require_relative "../support/matchers/be_single_line_directive"

RSpec.describe Bookdown::Directives::Screenshot do
  subject(:directive) { described_class.new("this is a title", "foo.html","blah.png", "640", "480", "foo") }

  specify { expect(directive).to be_single_line_directive }

  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize(
        "!SCREENSHOT \"this is a title\" blah.html blah.png","foo",
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
        "!SCREENSHOT \"this is a title\" blah.html blah.png 640","foo",
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
        "!SCREENSHOT \"this is a title\" blah.html blah.png 640 480","foo",
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
  describe "#execute" do
    it "runs PhantomJS to dump the console using the executable" do
      queue = directive.execute
      expect(queue).to have_command(
        Bookdown::Directives::Commands::PhantomJS,
        args: ["foo.html", "foo/blah.png","640","480"]
      )
    end
    it "outputs an image tag to the file" do
      queue = directive.execute
      expect(queue).to have_command(
        Bookdown::Directives::Commands::PutsToFileIO,
        string: "![this is a title](images/blah.png)"
      )
    end
  end
end
