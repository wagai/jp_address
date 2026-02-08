# frozen_string_literal: true

require_relative "lib/basho/version"

Gem::Specification.new do |spec|
  spec.name = "basho"
  spec.version = Basho::VERSION
  spec.authors = ["Hirotaka Wagai"]
  spec.email = ["hirotaka.wagai@gmail.com"]

  spec.summary = "Japanese address data (prefectures, cities, postal codes, regions) in a single gem"
  spec.description = "Provides prefectures, cities, postal codes, and regions as bundled JSON. " \
                     "Includes ActiveRecord integration."
  spec.homepage = "https://github.com/wagai/basho"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wagai/basho"
  spec.metadata["changelog_uri"] = "https://github.com/wagai/basho/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml tasks/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
