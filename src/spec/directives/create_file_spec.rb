require "spec_helper"
require "bookdown/directives/create_file"
require "pathname"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::CreateFile do
  describe "::recognize" do
    context "a CREATE_FILE directive with no options" do
      subject(:directive) {
        described_class.recognize("!CREATE_FILE blah.html")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename as a Pathname" do
        expect(directive.filename).to eq(Pathname("blah.html"))
      end
      it "parses empty options" do
        expect(directive.options).to eq([])
      end
    end
    context "a CREATE_FILE directive with options" do
      subject(:directive) {
        described_class.recognize("!CREATE_FILE{foo,bar} blah.html")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename as a Pathname" do
        expect(directive.filename).to eq(Pathname("blah.html"))
      end
      it "parses the options by splitting on a comma" do
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
    subject(:directive) { described_class.new("/tmp/blah/foo.html",[]) }
    it "warns if the file exists" do
      expect(directive.execute).to have_command(
        Bookdown::Directives::Commands::WarnIfFileExists
      )
    end
    it "removes the file if it exists" do
      expect(directive.execute).to have_command(
        Bookdown::Directives::Commands::MethodCall,
        object: FileUtils,
        method: :rm_rf,
        argument: Pathname("/tmp/blah/foo.html")
      )
    end
    it "ensures the directory exists where the file should go" do
      expect(directive.execute).to have_command(
        Bookdown::Directives::Commands::MethodCall,
        object: FileUtils,
        method: :mkdir_p,
        argument: Pathname("/tmp/blah")
      )
    end
    it "outputs a fenced code block based on the file type" do
      expect(directive.execute).to have_command(
        Bookdown::Directives::Commands::PutsToFileIO,
        string: "```html"
      )
    end

  end
  describe "#continue?" do
    subject(:directive) { described_class.new("/tmp/blah/foo.html",[]) }
    context "when the end directive has been found" do
      it "is false" do
        directive.append("!END CREATE_FILE")
        expect(directive.continue?).to eq(false)
      end
    end
    context "when first created" do
      specify { expect(directive.continue?).to eq(true) }
    end
    context "when lines have been parsed that are not the end directive" do
      it "is true" do
        directive.append("foo bar")
        expect(directive.continue?).to eq(true)
      end
    end
  end
  describe "#append" do
    subject(:directive) { described_class.new("/tmp/blah/foo.html",[]) }
    context "when the end directive has been found" do
      it "closes the fenced close block" do
        queue = directive.append("!END CREATE_FILE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "```"
        )
      end
    end
    context "when lines have been parsed that are not the end directive" do
      it "appends the line to the file" do
        queue = directive.append("foo bar blah")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::AppendToFileName,
          string: "foo bar blah",
          filename: Pathname("/tmp/blah/foo.html")
        )
      end
      it "appends the line to the markdown output" do
        queue = directive.append("foo bar blah")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "foo bar blah"
        )
      end
    end
  end
end
