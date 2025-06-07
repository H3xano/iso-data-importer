require "bundler/setup"
# This will load lib/iso-data-importer.rb, which in turn loads everything else.
require "iso-data-importer"

# For file utils in rake tasks
require "fileutils"

namespace :data do
  desc "Clean downloaded temp files and generated data"
  task :clean do
    puts "Cleaning tmp/ and data/ directories..."
    FileUtils.rm_rf("tmp")
    # Be careful with cleaning data/ if you don't want to lose it
    # For now, let's just clean specific subdirs if they are fully generated
    # FileUtils.rm_rf("data/deliverables")
    # FileUtils.rm_rf("data/committees")
    # FileUtils.rm_rf("data/ics")
    # Or, if you want to clean all generated data:
    # FileUtils.rm_rf("data")
    # FileUtils.mkdir_p("data") # Recreate top-level data dir
    # FileUtils.mkdir_p("data/deliverables")
    # FileUtils.mkdir_p("data/committees")
    # FileUtils.mkdir_p("data/ics")
    # Add .gitkeep files back if you remove and recreate
  end

  desc "Fetch all raw data from ISO Open Data sources"
  task :fetch_raw do
    puts "Fetching all raw data..."
    # This will eventually call methods on your scraper classes
    # Example:
    # scraper = Iso::Data::Importer::DeliverablesScraper.new
    # scraper.fetch_to_tmp
    # ... for other scrapers ...
    # For now, placeholder:
    # Iso::Data::Importer.instance.fetch_all_raw_data # If you build such an API
    puts "Raw data fetching (not yet implemented)."
  end

  desc "Process raw data into structured objects"
  task :process_raw do
    puts "Processing raw data..."
    # This will parse tmp/ files and create model instances
    # Example:
    # Iso::Data::Importer.instance.process_all_raw_data
    puts "Raw data processing (not yet implemented)."
  end

  desc "Export processed data to YAML files in data/"
  task :export_yaml do
    puts "Exporting data to YAML..."
    # This will take your processed objects and write them to data/
    # Example:
    # Iso::Data::Importer.instance.export_all_to_yaml
    puts "YAML export (not yet implemented)."
  end

  desc "Run all steps: clean, fetch, process, export"
  task all: [:clean, :fetch_raw, :process_raw, :export_yaml] do
    puts "All data import steps completed."
  end
end

task default: "data:all"

# If you have tests
begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task test: :spec
rescue LoadError
  # RSpec not available
end