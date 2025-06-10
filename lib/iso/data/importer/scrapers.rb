# lib/iso/data/importer/scrapers.rb
# frozen_string_literal: true

require_relative "scrapers/deliverables_scraper"
require_relative "scrapers/technical_committees_scraper"
require_relative "scrapers/ics_scraper"

module Iso
  module Data
    module Importer
      module Scrapers
        def self.fetch_deliverables(force_download: false)
          puts "INFO: Starting to fetch ISO Deliverables data..."
          scraper = DeliverablesScraper.new
          deliverables = []
          # Pass the force_download argument
          scraper.scrape(force_download: force_download) do |deliverable|
            deliverables << deliverable
          end
          puts "INFO: Fetched #{deliverables.size} ISO Deliverables."
          deliverables
        end

        def self.fetch_technical_committees(force_download: false)
          puts "INFO: Starting to fetch ISO Technical Committees data..."
          scraper = TechnicalCommitteesScraper.new
          committees = []
          # Pass the force_download argument
          scraper.scrape(force_download: force_download) do |committee|
            committees << committee
          end
          puts "INFO: Fetched #{committees.size} ISO Technical Committees."
          committees
        end

        def self.fetch_ics_entries(force_download: false)
          puts "INFO: Starting to fetch ISO ICS data..."
          scraper = IcsScraper.new
          ics_entries = []
          # CORRECTED: Pass the force_download argument from the method parameter
          scraper.scrape(force_download: force_download) do |ics_entry|
            ics_entries << ics_entry
          end
          puts "INFO: Fetched #{ics_entries.size} ISO ICS entries."
          ics_entries
        end

        def self.fetch_all(force_download: false)
          puts "INFO: Starting to fetch all ISO open data..."

          # These will now correctly pass down the force_download flag
          deliverables = fetch_deliverables(force_download: force_download)
          technical_committees = fetch_technical_committees(force_download: force_download)
          ics_entries = fetch_ics_entries(force_download: force_download)

          puts "INFO: Fetching complete."
          {
            deliverables: deliverables,
            technical_committees: technical_committees,
            ics_entries: ics_entries
          }
        end
      end
    end
  end
end