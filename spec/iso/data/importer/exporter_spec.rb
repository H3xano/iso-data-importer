# spec/iso/data/importer/exporter_spec.rb
require 'spec_helper'

require 'iso/data/importer/exporter'
require 'iso/data/importer/models/deliverable'
require 'iso/data/importer/models/deliverable_collection'
require 'iso/data/importer/models/technical_committee'
require 'iso/data/importer/models/technical_committee_collection'
require 'iso/data/importer/models/ics_entry'
require 'iso/data/importer/models/ics_entry_collection'

require 'fileutils'
require 'yaml'
require 'tmpdir'

RSpec.describe Iso::Data::Importer::Exporter do
  let(:temp_output_root) { Dir.mktmpdir("iso_exporter_spec_") }
  let(:data_output_dir_for_test) { temp_output_root }

  # Mock item hashes (what item.to_h would return)
  let(:deliverable1_item_hash) { { "id" => 1, "docidentifier" => "ISO 9001:2015", "type" => "IS" } }
  let(:deliverable2_item_hash) { { "id" => 2, "docidentifier" => "ISO/TR 10013", "type" => "TR" } }
  let(:mock_deliverable1) { double("Deliverable", reference: "ISO 9001:2015", id: 1, to_h: deliverable1_item_hash) }
  let(:mock_deliverable2) { double("Deliverable", reference: "ISO/TR 10013", id: 2, to_h: deliverable2_item_hash) }

  let(:tc1_item_hash) { { "id" => 101, "reference" => "ISO/TC 1", "status" => "Active" } }
  let(:mock_tc1) { double("TechnicalCommittee", reference: "ISO/TC 1", id: 101, to_h: tc1_item_hash) }

  let(:ics1_item_hash) { { "identifier" => "01.020", "titleEn" => "Terminology" } }
  let(:mock_ics1) { double("IcsEntry", identifier: "01.020", to_h: ics1_item_hash) }

  # This instance will be used by the tests, created once per describe block
  let!(:exporter_instance) do
    stub_const("Iso::Data::Importer::Exporter::DATA_OUTPUT_DIR", data_output_dir_for_test)
    described_class.new # `initialize` creates subdirectories
  end

  after(:all) do # Use after(:all) if temp_output_root is defined with `let` at top level
    # If temp_output_root was defined inside a describe block, use after(:each)
    # For simplicity, if it's top-level let, clean once after all tests in this file.
    # However, Dir.mktmpdir often cleans itself on process exit. Explicit is safer.
    # To be absolutely safe with `let`, clean after each example that might use it.
    # For now, assuming `Dir.mktmpdir` will be cleaned. If not, use an `after(:each)` hook.
  end
  # More robust cleanup for `let(:temp_output_root)` defined at the top level:
  # This might cause issues if another spec file also defines this constant.
  # Better to manage temp dirs per example group or per example.
  # Let's use an after(:each) for the root temp dir to be safe.
  after(:each) do
     FileUtils.rm_rf(temp_output_root) if Dir.exist?(temp_output_root)
     # Recreate for next test if needed by a let! or before(:all)
     # For this spec, exporter_instance is let!, so it's recreated.
  end


  describe '#initialize' do
    it 'creates the base output directory and individual file subdirectories' do
      expect(Dir.exist?(data_output_dir_for_test)).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR))).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::TC_SUBDIR))).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ICS_SUBDIR))).to be true
    end
  end

  describe '#clean_output_dirs' do
    let(:deliverables_ind_path) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR) }
    let(:deliverables_coll_file) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_DELIVERABLES_FILENAME) }

    before do
      FileUtils.mkdir_p(deliverables_ind_path) # Ensure individual dir exists
      FileUtils.touch(File.join(deliverables_ind_path, "dummy_ind.yaml"))
      FileUtils.touch(deliverables_coll_file)
    end

    it 'removes individual files when strategy is :individual_files' do
      exporter_instance.clean_output_dirs(strategy: :individual_files)
      expect(Dir.empty?(deliverables_ind_path)).to be true
      expect(File.exist?(deliverables_coll_file)).to be true # Should not touch this
    end

    it 'removes collection files when strategy is :collection' do
      exporter_instance.clean_output_dirs(strategy: :collection)
      expect(File.exist?(deliverables_coll_file)).to be false
      expect(File.exist?(File.join(deliverables_ind_path, "dummy_ind.yaml"))).to be true # Should not touch this
    end

    it 'defaults to :collection strategy for cleaning' do
      exporter_instance.clean_output_dirs # Default strategy
      expect(File.exist?(deliverables_coll_file)).to be false
      expect(File.exist?(File.join(deliverables_ind_path, "dummy_ind.yaml"))).to be true
    end
  end

  describe '#export_deliverables' do
    let(:deliverables) { [mock_deliverable1, mock_deliverable2] }
    let(:deliverables_collection) { Iso::Data::Importer::Models::DeliverableCollection.new(deliverables) }

    context 'with strategy: :collection (default)' do
      let(:collection_output_file) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_DELIVERABLES_FILENAME) }
      let(:expected_collection_hash) { { "deliverables" => [deliverable1_item_hash, deliverable2_item_hash] } }

      before do
        # Mock the collection's to_h method to return what we expect for the whole collection
        allow(deliverables_collection).to receive(:to_h).and_return(expected_collection_hash)
      end

      it 'writes all deliverables to a single YAML file' do
        exporter_instance.export_deliverables(deliverables_collection) # Relies on default strategy
        expect(File.exist?(collection_output_file)).to be true
        expect(YAML.load_file(collection_output_file)).to eq(expected_collection_hash)
      end
    end

    context 'with strategy: :individual_files' do
      let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR) }

      it 'writes each deliverable to a separate YAML file' do
        exporter_instance.export_deliverables(deliverables_collection, strategy: :individual_files)

        expected_file1_path = File.join(output_subdir, "ISO_9001_2015.yaml") # From mock_deliverable1.reference
        expected_file2_path = File.join(output_subdir, "ISO_TR_10013.yaml") # From mock_deliverable2.reference

        expect(File.exist?(expected_file1_path)).to be true
        expect(YAML.load_file(expected_file1_path)).to eq(deliverable1_item_hash)

        expect(File.exist?(expected_file2_path)).to be true
        expect(YAML.load_file(expected_file2_path)).to eq(deliverable2_item_hash)
      end
    end

    it 'does nothing if the collection is nil or empty for either strategy' do
      expect(File).not_to receive(:write)
      exporter_instance.export_deliverables(nil, strategy: :collection)
      exporter_instance.export_deliverables(Iso::Data::Importer::Models::DeliverableCollection.new([]), strategy: :collection)
      exporter_instance.export_deliverables(nil, strategy: :individual_files)
      exporter_instance.export_deliverables(Iso::Data::Importer::Models::DeliverableCollection.new([]), strategy: :individual_files)
    end
  end

  describe '#export_technical_committees' do
    let(:committees) { [mock_tc1] }
    let(:tc_collection) { Iso::Data::Importer::Models::TechnicalCommitteeCollection.new(committees) }

    context 'with strategy: :collection (default)' do
      let(:collection_output_file) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_TCS_FILENAME) }
      let(:expected_collection_hash) { { "technical_committees" => [tc1_item_hash] } }

      before do
        allow(tc_collection).to receive(:to_h).and_return(expected_collection_hash)
      end

      it 'writes all TCs to a single YAML file' do
        exporter_instance.export_technical_committees(tc_collection)
        expect(File.exist?(collection_output_file)).to be true
        expect(YAML.load_file(collection_output_file)).to eq(expected_collection_hash)
      end
    end

    context 'with strategy: :individual_files' do
      let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::TC_SUBDIR) }
      it 'writes each TC to a separate YAML file' do
        exporter_instance.export_technical_committees(tc_collection, strategy: :individual_files)
        expected_file_path = File.join(output_subdir, "ISO_TC_1.yaml")
        expect(File.exist?(expected_file_path)).to be true
        expect(YAML.load_file(expected_file_path)).to eq(tc1_item_hash)
      end
    end
  end

  describe '#export_ics_entries' do
    let(:ics_entries) { [mock_ics1] }
    let(:ics_collection) { Iso::Data::Importer::Models::IcsEntryCollection.new(ics_entries) }

    context 'with strategy: :collection (default)' do
      let(:collection_output_file) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ALL_ICS_FILENAME) }
      let(:expected_collection_hash) { { "ics_entries" => [ics1_item_hash] } }

      before do
        allow(ics_collection).to receive(:to_h).and_return(expected_collection_hash)
      end

      it 'writes all ICS entries to a single YAML file' do
        exporter_instance.export_ics_entries(ics_collection)
        expect(File.exist?(collection_output_file)).to be true
        expect(YAML.load_file(collection_output_file)).to eq(expected_collection_hash)
      end
    end

    context 'with strategy: :individual_files' do
      let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ICS_SUBDIR) }
      it 'writes each ICS entry to a separate YAML file' do
        exporter_instance.export_ics_entries(ics_collection, strategy: :individual_files)
        expected_file_path = File.join(output_subdir, "01_020.yaml") # From mock_ics1.identifier & sanitize
        expect(File.exist?(expected_file_path)).to be true
        expect(YAML.load_file(expected_file_path)).to eq(ics1_item_hash)
      end
    end
  end

  # Sanitize_filename tests remain the same as they test a private utility method
  describe '#sanitize_filename' do
    it 'replaces spaces with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO 12345 Part 1")).to eq("ISO_12345_Part_1")
    end
    it 'replaces colons with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO 9001:2015")).to eq("ISO_9001_2015")
    end
    it 'replaces slashes with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO/IEC 27001")).to eq("ISO_IEC_27001")
    end
    it 'replaces dots with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "01.020.30")).to eq("01_020_30")
    end
    it 'replaces multiple invalid chars with single underscores and removes leading/trailing' do
      expect(exporter_instance.send(:sanitize_filename, "File / : Name ? *")).to eq("File_Name")
      expect(exporter_instance.send(:sanitize_filename, "_Leading_Trailing_")).to eq("Leading_Trailing")
    end
  end
end