# frozen_string_literal: true

require_relative 'lib/sidekiq/redeploy/version'

Gem::Specification.new do |spec|
  spec.name = 'sidekiq-redeploy'
  spec.version = Sidekiq::Redeploy::VERSION
  spec.authors = ['tbeauvais']
  spec.email = ['tbeauvais1@gmail.com']

  spec.summary       = 'Sidekiq launcher to redeploy and reload app from artifact.'
  spec.description   = 'Sidekiq launcher to redeploy and reload app from a remote artifact. ' \
                       'This will detect app changes, once detected a new artifact ' \
                       'will be pulled and the Sidekiq app will be reloaded.'
  spec.homepage      = 'https://github.com/tbeauvais/sidekiq-redeploy'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.1.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/tbeauvais/sidekiq-redeploy'
  spec.metadata['changelog_uri'] = 'https://github.com/tbeauvais/sidekiq-redeploy/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir        = 'bin'
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 13.0.6'
  spec.add_development_dependency 'rspec', '~> 3.12.0'
  spec.add_development_dependency 'rubocop', '~> 1.43'
  spec.add_development_dependency 'rubocop-performance', '~> 1.15'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.17'
  spec.add_development_dependency 'rubocop-thread_safety', '~> 0.4.4'
  spec.add_development_dependency 'timecop', '~> 0.9.6'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
