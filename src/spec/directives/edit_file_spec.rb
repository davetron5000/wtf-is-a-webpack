require "spec_helper"
require "bookdown/directives/edit_file"
require "pathname"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::EditFile do
  subject(:directive) { described_class.new("/tmp/blah/foo.html","<!--","-->") }
  describe "::recognize" do
    context "a EDIT_FILE directive with no options" do
      subject(:directive) {
        described_class.recognize("!EDIT_FILE blah.html <!-- -->")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
      end
      it "parses the filename as a Pathname" do
        expect(directive.filename).to eq(Pathname("blah.html"))
      end
      it "parses the starting comment" do
        expect(directive.start_comment).to eq("<!--")
      end
      it "parses the end comment" do
        expect(directive.end_comment).to eq("-->")
      end
    end
    context "another directive" do
      it "does not create a new #{described_class}" do
        directive = described_class.recognize("!FOO_FILE blah.html")
        expect(directive).to be_nil
      end
    end
    context "without the comment delimiters" do
      it "blows up" do
        expect {
          described_class.recognize("!EDIT_FILE blah.html")
        }.to raise_error(/EDIT_FILE requires two or three args/)
      end
    end
  end
  describe "#execute" do
    it "returns nothing" do
      expect(directive.execute).to eq([])
    end
  end
  describe "#continue?" do
    context "when the end directive has been found" do
      it "is false" do
        directive.append("!END EDIT_FILE")
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
    context "when the end directive has been found" do
      it "opens the fenced close block" do
        queue = directive.append("!END EDIT_FILE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "```html"
        )
      end
      it "edits the file according to the instructions" do
        instructions = { "match" => "foo", "insert_before" => [ "foo", "bar" ] }
        queue = directive.append(instructions.to_json)
        queue = directive.append("!END EDIT_FILE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::EditFile,
          editing_instructions: [instructions]
        )
      end
      it "closes the fenced close block" do
        queue = directive.append("!END EDIT_FILE")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "```"
        )
      end
    end
    context "when lines have been parsed that are not the end directive" do
      it "returns nothing" do
        queue = directive.append("foo bar blah")
        expect(queue).to eq([])
      end
    end
  end
end
