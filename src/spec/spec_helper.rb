require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end
$: << File.expand_path(File.join(File.dirname(__FILE__),"..","lib"))
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.profile_examples = 5 if ENV["RSPEC_PROFILE"]

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
