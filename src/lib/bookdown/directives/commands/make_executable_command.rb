require_relative "base_command"
class Bookdown::Directives::Commands::MakeExecutableCommand < Bookdown::Directives::Commands::BaseCommand
  attr_reader :generated_source, :code
  def initialize(code,source)
    @code = code
    @source = source
    @generated_source = Tempfile.new(["do_and_screenshot",".js"])
  end

  def execute(_current_output_io,logger)
    File.open(@source).readlines.each do |line|
      if line =~ /::CUSTOM_CODE::/
        @code.each do |code_line|
          logger.info "Adding #{code_line} to #{@generated_source.path}"
          @generated_source.puts code_line
        end
      else
        @generated_source.puts line
      end
    end
    @generated_source.close
  end
end
