# spec/iso/data/importer/scrapers_spec.rb
require 'spec_helper'

# Require the main Scrapers module file
require 'iso/data/importer/scrapers'
# Require the model classes because the Scrapers module methods are typed to return them
require 'iso/data/importer/models/deliverable'
require 'iso/data/importer/models/technical_committee'
require 'iso/data/importer/models/ics_entry'

# We also need to require the individual scraper classes because we will be
# creating instances of them to stub their `scrape` method.
require 'iso/data/importer/scrapers/deliverables_scraper'
require 'iso/data/importer/scrapers/technical_committees_scraper'
require 'iso/data/importer/scrapers/ics_scraper'

RSpec.describe Iso::Data::Importer::Scrapers do
  # Create mock model instances for testing
  let(:mock_deliverable1) { instance_double(Iso::Data::Importer::Models::Deliverable, id: 1) }
  let(:mock_deliverable2) { instance_double(Iso::Data::Importer::Models::Deliverable, id: 2) }
  let(:mock_tc1) { instance_double(Iso::Data::Importer::Models::TechnicalCommittee, id: 101) }
  let(:mock_tc2) { instance_double(Iso::Data::Importer::Models::TechnicalCommittee, id: 102) }
  let(:mock_ics1) { instance_double(Iso::Data::Importer::Models::IcsEntry, identifier: "01.020") }
  let(:mock_ics2) { instance_double(Iso::Data::Importer::Models::IcsEntry, identifier: "03.040") }

  # Mock instances of the individual scrapers
  let(:deliverables_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::DeliverablesScraper) }
  let(:tc_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::TechnicalCommitteesScraper) }
  let(:ics_scraper_instance) { instance_double(Iso::Data::Importer::Scrapers::IcsScraper) }

  before do
    # Stub the .new method for each scraper class to return our mock instances
    allow(Iso::Data::Importer::Scrapers::DeliverablesScraper).to receive(:new).and_return(deliverables_scraper_instance)
    allow(Iso::Data::Importer::Scrapers::TechnicalCommitteesScraper).to receive(:new).and_return(tc_scraper_instance)
    allow(Iso::Data::Importer::Scrapers::IcsScraper).to receive(:new).and_return(ics_scraper_instance)

    # Default stub for scrape methods to yield nothing and return 0
    # This can be overridden in specific contexts if needed.
    allow(deliverables_scraper_instance).to receive(:scrape).and_return(0) # By default, yield nothing
    allow(tc_scraper_instance).to receive(:scrape).and_return(0)
    allow(ics_scraper_instance).to receive(:scrape).and_return(0)
  end

  describe '.fetch_deliverables' do
    it 'instantiates DeliverablesScraper and calls its scrape method' do
      # Expect scrape to be called and allow it to yield to collect items
      expect(deliverables_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_deliverable1)
        block.call(mock_deliverable2)
        2 # Return count
      end.with(force_download: false) # Check default argument

      result = described_class.fetch_deliverables # force_download defaults to false
      expect(result).to contain_exactly(mock_deliverable1, mock_deliverable2)
    end

    it 'passes force_download: true to the scraper' do
      expect(deliverables_scraper_instance).to receive(:scrape)
        .with(force_download: true) # Ensure this argument is passed
        .and_return(0)
      described_class.fetch_deliverables(force_download: true)
    end
  end

  describe '.fetch_technical_committees' do
    it 'instantiates TechnicalCommitteesScraper and calls its scrape method' do
      expect(tc_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_tc1)
        1 # Return count
      end.with(force_download: false)

      result = described_class.fetch_technical_committees
      expect(result).to contain_exactly(mock_tc1)
    end

    it 'passes force_download: true to the scraper' do
      expect(tc_scraper_instance).to receive(:scrape)
        .with(force_download: true)
        .and_return(0)
      described_class.fetch_technical_committees(force_download: true)
    end
  end

  describe '.fetch_ics_entries' do
    it 'instantiates IcsScraper and calls its scrape method' do
      expect(ics_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_ics1)
        block.call(mock_ics2)
        2
      end.with(force_download: false) # Check default, matches method signature in Scrapers module

      result = described_class.fetch_ics_entries
      expect(result).to contain_exactly(mock_ics1, mock_ics2)
    end

    it 'passes force_download: true to the scraper' do
      expect(ics_scraper_instance).to receive(:scrape)
        .with(force_download: true)
        .and_return(0)
      described_class.fetch_ics_entries(force_download: true)
    end
  end

  describe '.fetch_all' do
    before do
      # Setup individual scrapers to yield specific items for .fetch_all
      allow(deliverables_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_deliverable1); 1
      end
      allow(tc_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_tc1); block.call(mock_tc2); 2
      end
      allow(ics_scraper_instance).to receive(:scrape) do |&block|
        block.call(mock_ics1); 1
      end
    end

    it 'calls fetch methods for deliverables, technical_committees, and ics_entries' do
      # We can spy on the module's own methods
      expect(described_class).to receive(:fetch_deliverables).with(force_download: false).and_return([mock_deliverable1])
      expect(described_class).to receive(:fetch_technical_committees).with(force_download: false).and_return([mock_tc1, mock_tc2])
      expect(described_class).to receive(:fetch_ics_entries).with(force_download: false).and_return([mock_ics1])

      described_class.fetch_all # force_download defaults to false
    end

    it 'passes force_download: true to underlying fetch methods' do
      expect(described_class).to receive(:fetch_deliverables).with(force_download: true).and_return([])
      expect(described_class).to receive(:fetch_technical_committees).with(force_download: true).and_return([])
      expect(described_class).to receive(:fetch_ics_entries).with(force_download: true).and_return([])

      described_class.fetch_all(force_download: true)
    end

    it 'returns a hash containing arrays of all fetched items' do
      # Let the underlying methods run with the stubs defined in the before block
      # for this describe '.fetch_all' context.
      result = described_class.fetch_all

      expect(result).to be_a(Hash)
      expect(result.keys).to contain_exactly(:deliverables, :technical_committees, :ics_entries)
      expect(result[:deliverables]).to contain_exactly(mock_deliverable1)
      expect(result[:technical_committees]).to contain_exactly(mock_tc1, mock_tc2)
      expect(result[:ics_entries]).to contain_exactly(mock_ics1)
    end
  end
end