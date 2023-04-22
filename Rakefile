# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

begin
  # Add rubocop task
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  # Ignore
end

RSpec::Core::RakeTask.new(:spec)

task default: :spec
