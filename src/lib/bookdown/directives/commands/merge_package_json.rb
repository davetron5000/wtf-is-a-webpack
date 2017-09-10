require_relative "base_command"
class Bookdown::Directives::Commands::MergePackageJSON < Bookdown::Directives::Commands::BaseCommand
  attr_reader :json_to_merge
  def initialize(json_to_merge)
    @json_to_merge = json_to_merge
  end

  def execute(_current_output_io,_logger)
    existing_package_json = JSON.parse(File.read("package.json"))
    new_package_json = JSON.pretty_generate(existing_package_json.merge(@json_to_merge))
    File.open("package.json","w") do |file|
      file.puts(new_package_json)
    end
  rescue => ex
    raise "Problem parsing #{Pathname('package.json').expand_path}: #{ex.message}"
  end
end
