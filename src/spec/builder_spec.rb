require "spec_helper"
require "pathname"
require "fileutils"
require "bookdown/builder"
require "bookdown/book"

RSpec.describe Bookdown::Builder, :integration do
  describe "#build" do
    let(:src_dir)             { Pathname(__FILE__).dirname / "test_book" }
    let(:static_images_dir)   { src_dir / "images" }
    let(:markdown_dir)        { src_dir / "markdown" }
    let(:work_dir)            { src_dir / "work" }
    let(:parsed_markdown_dir) { src_dir / "parsed_markdown" }
    let(:site_dir)            { src_dir / "site" }
    let(:site_expected_dir)   { src_dir / "site_expected" }

    let(:book) {
      Bookdown::Book.new(
        src_dir: src_dir,
        static_images_dir: static_images_dir,
        markdown_dir: markdown_dir,
        work_dir: work_dir,
        parsed_markdown_dir: parsed_markdown_dir,
        site_dir: site_dir,
        title: "Foo",
        subtitle: "The Foo Story",
        author: "davetron5000"
      )
    }

    before do
      clean_up
    end
    after do
      #clean_up
    end
    def clean_up
      FileUtils.rm_rf static_images_dir
      FileUtils.rm_rf work_dir
      FileUtils.rm_rf parsed_markdown_dir
      FileUtils.rm_rf site_dir
    end

    class NilLogger
      def self.info(*)
      end
      def self.debug(*)
      end
      def self.warn(*)
      end
      def self.error(*)
      end
      def self.level
        99
      end
    end

    it "builds the book incrementally" do
      logger = if ENV["DEBUG"] == "true"
                 Logger.new(STDOUT).tap { |_| _.level = Logger::INFO }
               else
                 NilLogger
               end
      builder = described_class.new(logger: logger)
      builder.build(book)

      expect(File.exist?(site_dir / "chapter1.html")).to eq(true)
      expect(File.exist?(site_dir / "chapter2.html")).to eq(true)
      expect(File.exist?(site_dir / "chapter3.html")).to eq(true)
      expect(File.exist?(site_dir / "styles.css")).to eq(true)
      expect(File.exist?(site_dir / "images" / "image.png")).to eq(true)
      expect(File.exist?(site_dir / "images" / "updated.png")).to eq(true)

      [
        "chapter1.html",
        "chapter2.html",
        "chapter3.html",
        "styles.css",
      ].each do |file|
        produced_file = File.read(site_dir / file)
        expected_file = File.read(site_expected_dir / file)

        expect(produced_file).to eq(expected_file)
      end

      mtime = [
        File::Stat.new(site_dir / "chapter1.html").mtime,
        File::Stat.new(site_dir / "chapter2.html").mtime,
        File::Stat.new(site_dir / "chapter3.html").mtime,
      ]

      FileUtils.touch "#{markdown_dir / 'chapter2.md'}"
      builder.build(book)

      expect(File::Stat.new(site_dir / "chapter1.html").mtime).to eq(mtime[0])
      expect(File::Stat.new(site_dir / "chapter2.html").mtime).to be > mtime[1]
      expect(File::Stat.new(site_dir / "chapter3.html").mtime).to be > mtime[2]

      mtime = [
        File::Stat.new(site_dir / "chapter1.html").mtime,
        File::Stat.new(site_dir / "chapter2.html").mtime,
        File::Stat.new(site_dir / "chapter3.html").mtime,
      ]

      FileUtils.rm_rf work_dir / "saved-work" / "chapter3"

      builder.build(book)

      expect(File::Stat.new(site_dir / "chapter1.html").mtime).to eq(mtime[0])
      expect(File::Stat.new(site_dir / "chapter2.html").mtime).to eq(mtime[1])
      expect(File::Stat.new(site_dir / "chapter3.html").mtime).to be > mtime[2]
    end
  end
end
