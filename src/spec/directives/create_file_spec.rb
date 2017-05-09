require "spec_helper"
require "bookdown/directives/create_file"
require "pathname"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"

RSpec.describe Bookdown::Directives::CreateFile do
  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize("!CREATE_FILE blah.html", as: {
        filename: Pathname("blah.html"),
        options: []
      })
    end
    it "can parse a command with options" do
      expect(described_class).to recognize("!CREATE_FILE{foo,bar} blah.html", as: {
        filename: Pathname("blah.html"),
        options: ["foo","bar"]
      })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
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
