require "spec_helper"
require "bookdown/directives/screenshot"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::Screenshot do
  subject(:directive) { described_class.new("this is a title", "foo.html","blah.png", "640", "480", "foo") }
  describe "::recognize" do
    context "a SCREENSHOT directive with title, html file, and image name" do
      subject(:directive) {
        described_class.recognize("!SCREENSHOT \"this is a title\" blah.html blah.png","foo")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename" do
        expect(directive.html_file).to eq("blah.html")
      end
      it "parses the image name" do
        expect(directive.screenshot_image_name).to eq("blah.png")
      end
      it "sets a nil width" do
        expect(directive.width).to be_nil
      end
      it "sets a nil height" do
        expect(directive.height).to be_nil
      end
      it "passes through the screenshots dir" do
        expect(directive.screenshots_dir).to eq("foo")
      end
    end
    context "a SCREENSHOT directive with title, html file, image name, and width" do
      subject(:directive) {
        described_class.recognize("!SCREENSHOT \"this is a title\" blah.html blah.png 640","foo")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename" do
        expect(directive.html_file).to eq("blah.html")
      end
      it "parses the image name" do
        expect(directive.screenshot_image_name).to eq("blah.png")
      end
      it "sets the width" do
        expect(directive.width).to eq("640")
      end
      it "sets a nil height" do
        expect(directive.height).to be_nil
      end
      it "passes through the screenshots dir" do
        expect(directive.screenshots_dir).to eq("foo")
      end
    end
    context "a SCREENSHOT directive with title, html file, image name, width, and height" do
      subject(:directive) {
        described_class.recognize("!SCREENSHOT \"this is a title\" blah.html blah.png 640 480","foo")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename" do
        expect(directive.html_file).to eq("blah.html")
      end
      it "parses the image name" do
        expect(directive.screenshot_image_name).to eq("blah.png")
      end
      it "sets the width" do
        expect(directive.width).to eq("640")
      end
      it "sets the height" do
        expect(directive.height).to eq("480")
      end
      it "passes through the screenshots dir" do
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
