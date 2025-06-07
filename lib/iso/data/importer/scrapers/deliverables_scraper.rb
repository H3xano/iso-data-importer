# lib/iso/data/importer/scrapers/deliverables_scraper.rb
# frozen_string_literal: true

require_relative "base_scraper"
require_relative "../models/deliverable" # We'll define this model soon
require 'json' # For parsing JSONL lines

module Iso
  module Data
    module Importer
      module Scrapers
        # Scrapes/Processes ISO Deliverables metadata from the JSONL file.
        class DeliverablesScraper < BaseScraper
          # **ACTION: Replace with the actual direct download URL for ISO Deliverables JSONLines**
          SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/_latest/iso_deliverables_metadata/json/iso_deliverables_metadata.jsonl"
          TMP_FILE_PATH = "tmp/iso_deliverables.jsonl"

          # Fetches the deliverables data file to a temporary location.
          def fetch_source_file
            fetch_file(SOURCE_URL, TMP_FILE_PATH)
          end

          # Parses the downloaded JSONL file and yields Deliverable objects.
          # @return [Enumerator<Iso::Data::Importer::Models::Deliverable>]
          # If a block is given, it yields each Deliverable object.
          # Otherwise, it returns an array of Deliverable objects.
          def process_file(&block)
            unless File.exist?(TMP_FILE_PATH)
              log "Source file #{TMP_FILE_PATH} not found. Please run fetch_source_file first.", 0, :error
              return block_given? ? nil : []
            end

            log "Processing ISO Deliverables from #{TMP_FILE_PATH}..."
            deliverables = []

            File.foreach(TMP_FILE_PATH).with_index do |line, index|
              begin
                data_hash = JSON.parse(line)
                # **TODO: Map data_hash fields to Iso::Data::Importer::Models::Deliverable attributes**
                # This is where your detailed knowledge of the JSONL data model comes in.
                # Example (highly simplified, you need to map all relevant fields):
                deliverable = Iso::Data::Importer::Models::Deliverable.new(data_hash)

                if block_given?
                  yield deliverable
                else
                  deliverables << deliverable
                end

              rescue JSON::ParserError => e
                log "Failed to parse JSON on line #{index + 1}: #{e.message}. Line: #{line.strip}", 1, :error
                # Optionally, re-raise or collect errors
              rescue StandardError => e
                log "Error processing deliverable on line #{index + 1}: #{e.message}", 1, :error
                # Optionally, re-raise or collect errors
              end
            end

            log "Finished processing #{block_given? ? 'and yielding' : deliverables.size} deliverables."
            deliverables unless block_given?
          end
        end
      end
    end
  end
end