require "spec_helper"
require "bookdown/toc"
require "pathname"
require "json"

RSpec.describe Bookdown::TOC do
  describe "#each" do
    subject(:toc) do
      markdown_dir = Pathname(Dir.mktmpdir)
      toc = {
        toc: [
          {
            name: "chapter1",
            title: "Chapter One",
          },
          {
            name: "chapter2",
            title: "Chapter Two",
          },
          {
            name: "chapter3",
            title: "Chapter Three",
          },
        ]
      }
      File.open(markdown_dir / "toc.json", "w") do |file|
        file.puts(toc.to_json)
      end
      described_class.new(markdown_dir: markdown_dir)
    end

    it "parses each chapter's title" do
      expect(toc.to_a[0].title).to eq("Chapter One")
      expect(toc.to_a[1].title).to eq("Chapter Two")
      expect(toc.to_a[2].title).to eq("Chapter Three")
    end

    it "determines the names of the markdown files" do
      expect(toc.to_a[0].basename).to eq("chapter1.md")
      expect(toc.to_a[1].basename).to eq("chapter2.md")
      expect(toc.to_a[2].basename).to eq("chapter3.md")
    end

    it "determines the relative url of each chapter" do
      expect(toc.to_a[0].url).to eq("chapter1.html")
      expect(toc.to_a[1].url).to eq("chapter2.html")
      expect(toc.to_a[2].url).to eq("chapter3.html")
    end
    context "first chapter" do
      it "sets previous_chapter to nil" do
        expect(toc.to_a[0].previous_chapter).to be_nil
      end
      it "sets next_chapter to be the second chapter" do
        expect(toc.to_a[0].next_chapter).to eq(toc.to_a[1])
      end
    end
    context "middle chapter" do
      it "sets previous_chapter to the previous chapter" do
        expect(toc.to_a[1].previous_chapter).to eq(toc.to_a[0])
      end
      it "sets next_chapter to be the next chapter" do
        expect(toc.to_a[1].next_chapter).to eq(toc.to_a[2])
      end
    end
    context "last chapter" do
      it "sets previous_chapter to the previous chapter" do
        expect(toc.to_a[2].previous_chapter).to eq(toc.to_a[1])
      end
      it "sets next_chapter to nil" do
        expect(toc.to_a[2].next_chapter).to be_nil
      end
    end

  end
end
