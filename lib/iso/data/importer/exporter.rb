# lib/iso/data/importer/exporter.rb
# frozen_string_literal: true

require 'yaml'
require 'fileutils'

# Assuming models are loaded by the time Exporter is used by Orchestrator
# require_relative 'models/deliverable_collection'
# require_relative 'models/technical_committee_collection'
# require_relative 'models/ics_entry_collection'


module Iso
  module Data
    module Importer
      class Exporter
        DATA_OUTPUT_DIR = "data"
        DELIVERABLES_SUBDIR = "deliverables"
        TC_SUBDIR = "committees"
        ICS_SUBDIR = "ics"

        def initialize
          log("Initializing Exporter and ensuring output directories exist...", :info)
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, DELIVERABLES_SUBDIR))
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, TC_SUBDIR))
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, ICS_SUBDIR))
        end

        def ensure_output_directory(dir_path)
          FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
        end

        def clean_output_dirs
          log("Cleaning output directories...", :info)
          [DELIVERABLES_SUBDIR, TC_SUBDIR, ICS_SUBDIR].each do |subdir_name|
            dir_to_clean = File.join(DATA_OUTPUT_DIR, subdir_name)
            if Dir.exist?(dir_to_clean)
              log("Cleaning directory: #{dir_to_clean}", :info)
              FileUtils.rm_rf(Dir.glob(File.join(dir_to_clean, "*.*")))
            else
              ensure_output_directory(dir_to_clean)
            end
          end
          log("Output directories cleaned and ensured.", :info)
        end

        def export_deliverables(deliverable_collection)
          return unless deliverable_collection && deliverable_collection.size > 0
          log("Exporting #{deliverable_collection.size} deliverables to YAML...", :info)
          output_path = File.join(DATA_OUTPUT_DIR, DELIVERABLES_SUBDIR)
          deliverable_collection.each do |deliverable|
            filename_base = deliverable.reference || "unknown_deliverable_#{deliverable.id}"
            filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
            data_hash = deliverable.to_h # Relying on Lutaml's default
            File.write(filepath, data_hash.to_yaml)
          end
          log("Deliverables export complete to #{output_path}", :info)
        end

        def export_technical_committees(tc_collection)
          return unless tc_collection && tc_collection.size > 0
          log("Exporting #{tc_collection.size} technical committees to YAML...", :info)
          output_path = File.join(DATA_OUTPUT_DIR, TC_SUBDIR)
          tc_collection.each do |committee|
            filename_base = committee.reference || "unknown_tc_#{committee.id}"
            filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
            data_hash = committee.to_h
            File.write(filepath, data_hash.to_yaml)
          end
          log("Technical committees export complete to #{output_path}", :info)
        end

        def export_ics_entries(ics_collection)
          return unless ics_collection && ics_collection.size > 0
          log("Exporting #{ics_collection.size} ICS entries to YAML...", :info)
          output_path = File.join(DATA_OUTPUT_DIR, ICS_SUBDIR)
          ics_collection.each do |ics_entry|
            filename_base = ics_entry.identifier || "unknown_ics_#{Time.now.to_i}" # Fallback for ICS
            filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
            data_hash = ics_entry.to_h
            File.write(filepath, data_hash.to_yaml)
          end
          log("ICS entries export complete to #{output_path}", :info)
        end

        private

        def sanitize_filename(name_string)
          name_string.to_s
                     .gsub(/[\s:\.\/\\<>|"?*]+/, '_') # Added dot to be replaced
                     .gsub(/_+/, '_')                # Collapse multiple underscores
                     .gsub(/^_|_$/, '')              # Remove leading or trailing underscores
        end

        def log(message, severity = :info)
          prefix = case severity
                   when :error then "ERROR: "
                   when :warn  then "WARN:  "
                   else            "INFO:  "
                   end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{prefix}#{message}"
        end
      end
    end
  end
end