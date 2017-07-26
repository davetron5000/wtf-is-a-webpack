require "spec_helper"
require "bookdown/directives/ad"
require "bookdown/directives/commands/puts_to_file_io"
require_relative "../support/matchers/have_command"
require_relative "../support/matchers/recognize"
require_relative "../support/matchers/be_single_line_directive"

RSpec.describe Bookdown::Directives::Ad do

  specify { expect(described_class.new("benefit","subhead","link","call to action","/image.png")).to be_single_line_directive }

  describe "::recognize" do
    it "can parse a command with no options" do
      expect(described_class).to recognize(
        "!AD benefit \"this is a subhead\" https://google.com \"do it\" /images/foo.png",
        as: {
          h1: "benefit",
          h2: "this is a subhead",
          image: "/images/foo.png",
          link: "https://google.com",
          link_text: "do it",
        }
      )
    end
    it "ignores other directives" do
      expect(described_class).not_to recognize("!BLAH")
    end
  end
  describe "#execute" do
    context "with an image" do
      subject(:directive) { described_class.new("Buy my shit","It has stuff you will like","http://buy.now","Buy It!","/images/buy.png") }
      it "outputs the ad markup to the file" do
        queue = directive.execute
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: %{
<aside class="ad">
  <div class="banner">Promotion</div>
  <h1>Buy my shit</h1>
  <h2>It has stuff you will like</h2>
  <a href="http://buy.now">
    <img src="/images/buy.png" width="200"/>
  </a>
  <h3>
    <a href="http://buy.now">
      Buy It!
    </a>
  </h3>
</aside>
})
      end
    end
    context "without an image" do
      subject(:directive) { described_class.new("Buy my shit","It has stuff you will like","http://buy.now","Buy It!") }
      it "outputs the ad markup minus the image to the file" do
        queue = directive.execute
        expect(queue).to have_command(
          Bookdown::Directives::Commands::PutsToFileIO,
          string: %{
<aside class="ad">
  <div class="banner">Promotion</div>
  <h1>Buy my shit</h1>
  <h2>It has stuff you will like</h2>
  <h3>
    <a href="http://buy.now">
      Buy It!
    </a>
  </h3>
</aside>
})
      end
    end
  end
end
