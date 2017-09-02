require "spec_helper"
require "bookdown/book"
require "pathname"

RSpec.describe Bookdown::Book do
  subject(:book) {
    described_class.new(
      src_dir: "src",
      static_images_dir: "/foo",
      markdown_dir: "/bar",
      work_dir: "/bax",
      parsed_markdown_dir: "markdown",
      site_dir: "/quux",
      author: "davetron500",
      title: "Test Book",
      subtitle: "The truth about testing"
    )
  }
  describe "#scss_dir" do
    it "should be in 'scss' relative to src_dir, as a Pathname" do
      expect(book.scss_dir).to eq(Pathname("src/scss"))
    end
  end
  describe "#html_dir" do
    it "should be in 'html' relative to src_dir, as a Pathname" do
      expect(book.html_dir).to eq(Pathname("src/html"))
    end
  end
  describe "#images_dir" do
    it "should be in 'imges' relative to parsed_markdown_dir, as a Pathname, expanded" do
      expect(book.images_dir).to eq(Pathname("markdown/images").expand_path)
    end
  end
end
