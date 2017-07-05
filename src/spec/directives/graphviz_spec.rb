require "spec_helper"
require "bookdown/directives/graphviz"
require "pathname"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"

RSpec.describe Bookdown::Directives::Graphviz do
  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize("!GRAPHVIZ bar Some Graph", "foo", as: {
        filename: Pathname("bar.png"),
        dot_file: Pathname("bar.dot"),
        screenshots_dir: Pathname("foo"),
        description: "Some Graph"
      })
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
    end
  end
  describe "#execute" do
    subject(:directive) { described_class.new("bar.png","Some Graph", "foo") }
    it "outputs nothing" do
      expect(directive.execute).to eq([])
    end
  end
  describe "#continue?" do
    subject(:directive) { described_class.new("bar.png","Some Graph", "foo") }
    context "when the end directive has been found" do
      it "is false" do
        directive.append("!END GRAPHVIZ")
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
    subject(:directive) { described_class.new("bar","Some Graph", "foo") }
    context "when the end directive has been found" do
      it "runs Graphviz and writes the file" do
        dot_file = Pathname("foo") / "bar.dot"
        png_file = Pathname("foo") / "bar.png"

        directive.append("digraph foo {")
        directive.append("  Foo -> Bar [label=\"some label\"]")
        directive.append("}")
        queue = directive.append("!END GRAPHVIZ")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::MethodCall,
          object: FileUtils,
          method: :rm_rf,
          argument: dot_file
        )
        expect(queue).to have_command(
          Bookdown::Directives::Commands::AppendToFileName,
          filename: dot_file,
          string: "digraph foo {"
        )
        expect(queue).to have_command(
          Bookdown::Directives::Commands::AppendToFileName,
          filename: dot_file,
          string: "  Foo -> Bar [label=\"some label\"]"
        )
        expect(queue).to have_command(
          Bookdown::Directives::Commands::AppendToFileName,
          filename: dot_file,
          string: "}"
        )
        expect(queue).to have_command(
          Bookdown::Directives::Commands::Sh,
          command: "dot -Tpng #{dot_file} -o#{png_file}",
          expecting_success: true,
          show_output: false
        )
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: "<a class=\"embiggen-image\" href=\"images/bar.png\"><img src=\"images/bar.png\" alt=\"Some Graph\"><br><small>Click to Embiggen</small></a>"
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
