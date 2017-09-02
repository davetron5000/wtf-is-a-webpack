require "spec_helper"
require "bookdown/renderer"
require "bookdown/toc"
require "bookdown/book"
require "tempfile"

RSpec.describe Bookdown::Renderer do

  subject(:renderer) { described_class.new }

  describe "#render" do
    let(:book) {
      Bookdown::Book.new(
        src_dir: "src",
        static_images_dir: "/foo",
        markdown_dir: "/bar",
        work_dir: "/bax",
        parsed_markdown_dir: "markdown",
        site_dir: "/quux",
        author: "davetron5000",
        title: "Test Book",
        subtitle: "The truth about testing"
      )
    }
    let(:template) {
      file = Tempfile.new("template")
      File.open(file,"w") do |template|
        template.puts "<%= book.title %>:<%= book.subtitle %>:<%= book.author %>:<%= show_full_header ? 'FULL HEADER' : 'NORMAL HEADER' %>,<%= chapter.title %>"
        template.puts "<%= html %>"
      end
      file
    }
    let(:parsed_markdown_file) {
      file = Tempfile.new("markdown")
      File.open(file,"w") do |markdown|
        markdown.puts "# This is markdown"
        markdown.puts
        markdown.puts "* as is this"
        markdown.puts "* and this"
      end
      file
    }
    let(:html_file) {
      Tempfile.new("html")
    }

    before do
      @tmpfiles = [
        template,
        parsed_markdown_file,
        html_file
      ]
    end

    after do
      @tmpfiles.each(&:close)
    end

    context "first chapter" do
      it "renders the given template, showing the full header" do
        chapter = Bookdown::TOC::Chapter.new(hash: { "title" => "This is the title"})

        subject.render(book: book,
                       chapter: chapter,
                       template: template.path,
                       toc: [],
                       parsed_markdown_file: parsed_markdown_file.path,
                       html_file: html_file.path)

        rendered_content = File.read(html_file.path)
        expect(rendered_content).to eq("Test Book:The truth about testing:davetron5000:FULL HEADER,This is the title\n<h1 id=\"this-is-markdown\">This is markdown</h1>\n\n<ul>\n<li>as is this</li>\n<li>and this</li>\n</ul>\n\n")
      end
    end
    context "not first chapter" do
      it "renders the given template, NOT showing the full header" do
        chapter = Bookdown::TOC::Chapter.new(hash: { "title" => "This is the title"})
        chapter.previous_chapter = Bookdown::TOC::Chapter.new(hash: { "title" => "Prev chapter"})
        chapter.previous_chapter.next_chapter = chapter # for sanity

        subject.render(book: book,
                       chapter: chapter,
                       template: template.path,
                       toc: [],
                       parsed_markdown_file: parsed_markdown_file.path,
                       html_file: html_file.path)

        rendered_content = File.read(html_file.path)
        expect(rendered_content).to eq("Test Book:The truth about testing:davetron5000:NORMAL HEADER,This is the title\n<h1 id=\"this-is-markdown\">This is markdown</h1>\n\n<ul>\n<li>as is this</li>\n<li>and this</li>\n</ul>\n\n")
      end
    end
  end
end
