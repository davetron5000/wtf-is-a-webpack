require "spec_helper"
require "bookdown/directives/package_json"
require_relative "../support/matchers/have_command"

RSpec.describe Bookdown::Directives::PackageJson do
  subject(:directive) { described_class.new }
  describe "::recognize" do
    context "a PACKAGE_JSON directive" do
      subject(:directive) {
        described_class.recognize("!PACKAGE_JSON")
      }
      it "initializes a #{described_class}" do
        expect(directive.class).to eq(described_class)
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
    it "returns no commands" do
      expect(directive.execute).to eq([])
    end
  end
  describe "#continue?" do
    context "when the end directive has been found" do
      it "is false" do
        directive.append("{}")
        directive.append("!END PACKAGE_JSON")
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
    context "end directive reached" do

      let(:to_merge) {
        {
          "scripts" => {
            "foo" => "bar",
            "blah" => "crud",
          }
        }
      }
      before do
        directive.append(to_merge.to_json)
      end
      it "merges the parsed JSON with the existing package.json file" do
        queue = directive.append("!END PACKAGE_JSON")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::MergePackageJSON,
          json_to_merge: to_merge
        )
      end
      it "outputs the JSON being added to the file" do
        queue = directive.append("!END PACKAGE_JSON")
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: JSON.pretty_generate(to_merge)
        )
      end
    end
    context "inside the directive" do
      it "returns no commands" do
        queue = directive.append("foo")
        expect(queue).to eq([])
      end
    end
  end
end
