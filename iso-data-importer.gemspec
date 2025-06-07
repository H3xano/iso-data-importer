# frozen_string_literal: true

# This line will require the version file you'll create soon
require_relative "lib/iso/data/importer/version"

Gem::Specification.new do |spec|
  spec.name          = "iso-data-importer"
  spec.version       = Iso::Data::Importer::VERSION # Assumes you'll define this constant
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary = <<~SUMMARY
    Fetches and processes ISO Open Data for deliverables, technical committees, and ICS.
  SUMMARY
  spec.description = <<~DESCRIPTION
    iso-data-importer provides tools to download, parse, and store metadata from
    the ISO Open Data initiative (https://www.iso.org/open-data.html).
    It handles ISO deliverables, technical committees (TCs), and the
    International Classification for Standards (ICS), making this data
    available in a structured YAML format for offline use and integration.
  DESCRIPTION
  spec.homepage      = "https://github.com/metanorma/iso-data-importer" # CHANGE THIS
  spec.license       = "BSD-2-Clause" 

  # Specify a minimum Ruby version. Check what other Metanorma tools use.
  # Ruby 3.0.0 is a reasonable modern choice if not otherwise specified.
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  # Runtime dependencies:
  # For command-line interface (like ietf-data-importer uses Thor)
  spec.add_dependency "thor", "~> 1.0" # If you plan a CLI similar to ietf-data-importer's `fetch` command

  # For HTTP requests
  spec.add_dependency "faraday", "~> 2.7" # Or your preferred HTTP client, check latest stable version
  spec.add_dependency "faraday-follow_redirects", "~> 0.3.0" # If download URLs might have redirects

  # For parsing JSONLines (Ruby's built-in 'json' is usually sufficient,
  # but if you need a dedicated JSONL parser for streaming large files, consider it)
  # Built-in 'json' is part of Ruby standard library.

  # For parsing CSV (for ICS data)
  # Built-in 'csv' is part of Ruby standard library.

  # For YAML generation
  # Built-in 'psych' (which backs 'yaml') is part of Ruby standard library.
  # spec.add_dependency "yaml" # Not strictly necessary if relying on built-in Psych

  # If you decide to use lutaml-model based on ietf-data-importer pattern
  # spec.add_dependency "lutaml-model", "~> 0.7" # Check latest version

  # Files to include in the gem package
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    # Includes all files tracked by git, excluding test/spec/features
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  # Directory for executables
  spec.bindir        = "exe" # Changed from 'exe' to 'bin' to match Bundler's default gem skeleton
                               # Or change your directory from bin/ to exe/ to match ietf-data-importer

  # If you create an executable, e.g., bin/iso-data-importer
  # Bundler's default (bin/) is fine, or change to exe/ to match ietf-data-importer
  spec.executables   = spec.files.grep(%r{\A(?:bin|exe)/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end