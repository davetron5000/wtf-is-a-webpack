require "spec_helper"
require "bookdown/language"

RSpec.describe Bookdown::Language do
  describe "#to_s" do
    it "returns 'javascript' for a .js file" do
      expect(described_class.new("foo.js").to_s).to eq("javascript")
    end
    it "returns 'html' for a .html file" do
      expect(described_class.new("foo.html").to_s).to eq("html")
    end
    it "returns 'css' for a .css file" do
      expect(described_class.new("foo.css").to_s).to eq("css")
    end
    it "blows up if it can't figure out the language" do
      expect {
        described_class.new("blah.ex")
      }.to raise_error(/Can't determine language for blah.ex/)
    end
  end
end
