# frozen_string_literal: true

require_relative 'lib/active_typed_store/version'

Gem::Specification.new do |spec|
  spec.name          = 'active_typed_store'
  spec.version       = ActiveTypedStore::VERSION
  spec.authors       = ['Ermolaev Andrey']
  spec.email         = ['andruhafirst@yandex.ru']

  spec.summary       = 'Typed store for active records json/hstore columns'
  spec.homepage      = 'https://github.com/corp-gp/active_typed_store'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/corp-gp/active_typed_store'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    Dir.chdir(File.expand_path(__dir__)) do
      `git ls-files -z`.split("\x0").reject do |f|
        (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
      end
    end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'activemodel'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'activesupport'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
  }
end
