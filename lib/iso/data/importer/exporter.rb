# lib/iso/data/importer/exporter.rb
# frozen_string_literal: true

require 'yaml'
require 'fileutils'

# Ensure models are loaded. In a real gem, this would be handled by the main require.
require_relative 'models/deliverable_collection'
require_relative 'models/technical_committee_collection'
require_relative 'models/ics_entry_collection'
# Item models are required by their collections

module Iso
  module Data
    module Importer
      class Exporter
        DATA_OUTPUT_DIR = "data"
        DELIVERABLES_SUBDIR = "deliverables" # Used for individual file strategy
        TC_SUBDIR = "committees"          # Used for individual file strategy
        ICS_SUBDIR = "ics"                # Used for individual file strategy

        # Filenames for collection-level export
        ALL_DELIVERABLES_FILENAME = "deliverables.yaml"
        ALL_TCS_FILENAME = "committees.yaml"
        ALL_ICS_FILENAME = "ics.yaml"

        def initialize
          log("Initializing Exporter...", :info)
          # Ensure base data directory exists
          ensure_output_directory(DATA_OUTPUT_DIR)
          # For individual file strategy, ensure subdirectories exist
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, DELIVERABLES_SUBDIR))
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, TC_SUBDIR))
          ensure_output_directory(File.join(DATA_OUTPUT_DIR, ICS_SUBDIR))
        end

        def ensure_output_directory(dir_path)
          FileUtils.mkdir_p(dir_path) unless Dir.exist?(dir_path)
        end

        def clean_output_dirs(strategy: :collection) # Strategy might influence cleaning too
          log("Cleaning output directories (strategy: #{strategy})...", :info)
          if strategy == :individual_files
            [DELIVERABLES_SUBDIR, TC_SUBDIR, ICS_SUBDIR].each do |subdir_name|
              dir_to_clean = File.join(DATA_OUTPUT_DIR, subdir_name)
              if Dir.exist?(dir_to_clean)
                log("Cleaning individual files directory: #{dir_to_clean}", :info)
                FileUtils.rm_rf(Dir.glob(File.join(dir_to_clean, "*.yaml")))
              else
                ensure_output_directory(dir_to_clean)
              end
            end
          else # :collection strategy or unknown
            # Clean the collection-level files
            FileUtils.rm_f(File.join(DATA_OUTPUT_DIR, ALL_DELIVERABLES_FILENAME))
            FileUtils.rm_f(File.join(DATA_OUTPUT_DIR, ALL_TCS_FILENAME))
            FileUtils.rm_f(File.join(DATA_OUTPUT_DIR, ALL_ICS_FILENAME))
            log("Collection-level YAML files cleaned.", :info)
          end
          log("Output directories cleaning process complete for strategy: #{strategy}.", :info)
        end

        # Exports a collection of deliverables.
        # @param deliverable_collection [Iso::Data::Importer::Models::DeliverableCollection]
        # @param strategy [Symbol] :collection (default) for one file, or :individual_files
        def export_deliverables(deliverable_collection, strategy: :collection)
          return unless deliverable_collection && deliverable_collection.size > 0

          log("Exporting #{deliverable_collection.size} deliverables (strategy: #{strategy})...", :info)

          if strategy == :individual_files
            output_path = File.join(DATA_OUTPUT_DIR, DELIVERABLES_SUBDIR)
            deliverable_collection.each do |deliverable|
              filename_base = deliverable.reference || "unknown_deliverable_#{deliverable.id}"
              filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
              data_hash = deliverable.to_h # Individual item's hash
              File.write(filepath, data_hash.to_yaml)
            end
            log("Deliverables export (individual files) complete to #{output_path}", :info)
          else # Default to :collection strategy
            filepath = File.join(DATA_OUTPUT_DIR, ALL_DELIVERABLES_FILENAME)
            # The DeliverableCollection.to_h should produce { deliverables: [item1_hash, item2_hash,...] }
            collection_hash = deliverable_collection.to_h
            File.write(filepath, collection_hash.to_yaml)
            log("Deliverables export (collection file) complete to #{filepath}", :info)
          end
        end

        # Exports a collection of technical committees.
        # @param tc_collection [Iso::Data::Importer::Models::TechnicalCommitteeCollection]
        # @param strategy [Symbol] :collection (default) or :individual_files
        def export_technical_committees(tc_collection, strategy: :collection)
          return unless tc_collection && tc_collection.size > 0
          log("Exporting #{tc_collection.size} technical committees (strategy: #{strategy})...", :info)

          if strategy == :individual_files
            output_path = File.join(DATA_OUTPUT_DIR, TC_SUBDIR)
            tc_collection.each do |committee|
              filename_base = committee.reference || "unknown_tc_#{committee.id}"
              filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
              data_hash = committee.to_h
              File.write(filepath, data_hash.to_yaml)
            end
            log("Technical committees export (individual files) complete to #{output_path}", :info)
          else # :collection strategy
            filepath = File.join(DATA_OUTPUT_DIR, ALL_TCS_FILENAME)
            collection_hash = tc_collection.to_h
            File.write(filepath, collection_hash.to_yaml)
            log("Technical committees export (collection file) complete to #{filepath}", :info)
          end
        end

        # Exports a collection of ICS entries.
        # @param ics_collection [Iso::Data::Importer::Models::IcsEntryCollection]
        # @param strategy [Symbol] :collection (default) or :individual_files
        def export_ics_entries(ics_collection, strategy: :collection)
          return unless ics_collection && ics_collection.size > 0
          log("Exporting #{ics_collection.size} ICS entries (strategy: #{strategy})...", :info)

          if strategy == :individual_files
            output_path = File.join(DATA_OUTPUT_DIR, ICS_SUBDIR)
            ics_collection.each do |ics_entry|
              filename_base = ics_entry.identifier || "unknown_ics_#{Time.now.to_i}"
              filepath = File.join(output_path, "#{sanitize_filename(filename_base)}.yaml")
              data_hash = ics_entry.to_h
              File.write(filepath, data_hash.to_yaml)
            end
            log("ICS entries export (individual files) complete to #{output_path}", :info)
          else # :collection strategy
            filepath = File.join(DATA_OUTPUT_DIR, ALL_ICS_FILENAME)
            collection_hash = ics_collection.to_h
            File.write(filepath, collection_hash.to_yaml)
            log("ICS entries export (collection file) complete to #{filepath}", :info)
          end
        end

        private

        def sanitize_filename(name_string)
          name_string.to_s
                     .gsub(/[\s:\.\/\\<>|"?*]+/, '_')
                     .gsub(/_+/, '_')
                     .gsub(/^_|_$/, '')
        end

        def log(message, severity = :info)
          prefix = case severity
                   when :error then "ERROR: "
                   when :warn  then "WARN:  "
                   else            "INFO:  " # Default to INFO prefix
                   end
          puts "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} #{prefix}#{message}"
        end
      end
    end
  end
end