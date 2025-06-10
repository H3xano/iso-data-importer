# spec/iso/data/importer/exporter_spec.rb
require 'spec_helper'

require 'iso/data/importer/exporter'
# Require models for type checking by `double` if you want (though double doesn't enforce it like instance_double)
# However, for clarity, it's good to have them required.
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
  # No need for `let(:exporter)` if we use `@exporter_instance` initialized in `before`
  let(:temp_output_root) { Dir.mktmpdir("iso_exporter_spec_") }
  let(:data_output_dir_for_test) { temp_output_root }

  # Mock model items - using `double` instead of `instance_double` to avoid to_h verification issues
  let(:deliverable1_hash) { { "id" => 1, "docidentifier" => "ISO 9001:2015", "type" => "IS" } } # This is what .to_h might return
  let(:deliverable2_hash) { { "id" => 2, "docidentifier" => "ISO/TR 10013", "type" => "TR" } }
  # For mocks, ensure `reference` or `identifier` matches what sanitize_filename expects for consistent testing
  let(:mock_deliverable1) { double("Deliverable", reference: "ISO 9001:2015", id: 1, to_h: deliverable1_hash) }
  let(:mock_deliverable2) { double("Deliverable", reference: "ISO/TR 10013", id: 2, to_h: deliverable2_hash) }

  let(:tc1_hash) { { "id" => 101, "reference" => "ISO/TC 1", "status" => "Active" } }
  let(:mock_tc1) { double("TechnicalCommittee", reference: "ISO/TC 1", id: 101, to_h: tc1_hash) }

  let(:ics1_hash) { { "identifier" => "01.020", "titleEn" => "Terminology" } }
  let(:mock_ics1) { double("IcsEntry", identifier: "01.020", to_h: ics1_hash) }

  # This instance will be used by the tests
  let!(:exporter_instance) do # Use let! to ensure it's created before each test in this block
    # Stub the constant *before* Exporter is instantiated for the tests
    stub_const("Iso::Data::Importer::Exporter::DATA_OUTPUT_DIR", data_output_dir_for_test)
    described_class.new
  end

  after do
    FileUtils.rm_rf(temp_output_root)
  end

  describe '#initialize' do
    it 'creates the output subdirectories' do
      # Exporter is initialized via let! above, so directories should be created
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR))).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::TC_SUBDIR))).to be true
      expect(Dir.exist?(File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ICS_SUBDIR))).to be true
    end
  end

  describe '#clean_output_dirs' do
    let(:deliverables_path) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR) }
    let(:tc_path) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::TC_SUBDIR) }

    before do
      FileUtils.mkdir_p(deliverables_path) # Ensure dirs exist for FileUtils.touch
      FileUtils.mkdir_p(tc_path)
      FileUtils.touch(File.join(deliverables_path, "dummy1.yaml"))
      FileUtils.touch(File.join(tc_path, "dummy2.yaml"))
    end

    it 'removes files from the output directories but keeps directories' do
      expect(File.exist?(File.join(deliverables_path, "dummy1.yaml"))).to be true # Pre-check
      exporter_instance.clean_output_dirs
      expect(Dir.exist?(deliverables_path)).to be true
      expect(Dir.exist?(tc_path)).to be true
      expect(Dir.empty?(deliverables_path)).to be true
      expect(Dir.empty?(tc_path)).to be true
    end
  end

  describe '#export_deliverables' do
    let(:deliverables_collection) { Iso::Data::Importer::Models::DeliverableCollection.new([mock_deliverable1, mock_deliverable2]) }
    let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::DELIVERABLES_SUBDIR) }

    it 'writes each deliverable to a YAML file in the correct subdirectory' do
      exporter_instance.export_deliverables(deliverables_collection)

      expected_file1_path = File.join(output_subdir, "ISO_9001_2015.yaml")
      expected_file2_path = File.join(output_subdir, "ISO_TR_10013.yaml")

      expect(File.exist?(expected_file1_path)).to be true
      expect(File.exist?(expected_file2_path)).to be true

      file1_content = YAML.load_file(expected_file1_path)
      expect(file1_content).to eq(deliverable1_hash)
    end

    it 'does nothing if the collection is nil or empty' do
      expect(File).not_to receive(:write)
      exporter_instance.export_deliverables(nil)
      exporter_instance.export_deliverables(Iso::Data::Importer::Models::DeliverableCollection.new([]))
    end

    it 'handles deliverables with nil reference for filename generation' do
        nil_ref_deliverable_hash = { "id" => 99, "type" => "IS" }
        mock_nil_ref_deliverable = double("Deliverable", reference: nil, id: 99, to_h: nil_ref_deliverable_hash)
        collection = Iso::Data::Importer::Models::DeliverableCollection.new([mock_nil_ref_deliverable])
        
        exporter_instance.export_deliverables(collection)
        
        expected_filename = "unknown_deliverable_99.yaml" # From Exporter's fallback
        expect(File.exist?(File.join(output_subdir, expected_filename))).to be true
    end
  end

  describe '#export_technical_committees' do
    let(:tc_collection) { Iso::Data::Importer::Models::TechnicalCommitteeCollection.new([mock_tc1]) }
    let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::TC_SUBDIR) }

    it 'writes each technical committee to a YAML file' do
      exporter_instance.export_technical_committees(tc_collection)
      expected_file_path = File.join(output_subdir, "ISO_TC_1.yaml")
      expect(File.exist?(expected_file_path)).to be true
      expect(YAML.load_file(expected_file_path)).to eq(tc1_hash)
    end
  end

  describe '#export_ics_entries' do
    let(:ics_collection) { Iso::Data::Importer::Models::IcsEntryCollection.new([mock_ics1]) }
    let(:output_subdir) { File.join(data_output_dir_for_test, Iso::Data::Importer::Exporter::ICS_SUBDIR) }

    it 'writes each ICS entry to a YAML file' do
      exporter_instance.export_ics_entries(ics_collection)
      # With sanitize_filename now replacing '.', "01.020" -> "01_020.yaml"
      expected_file_path = File.join(output_subdir, "01_020.yaml")
      expect(File.exist?(expected_file_path)).to be true
      expect(YAML.load_file(expected_file_path)).to eq(ics1_hash)
    end
  end

  describe '#sanitize_filename' do
    # Use the memoized exporter_instance for testing the private method
    it 'replaces spaces with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO 12345 Part 1")).to eq("ISO_12345_Part_1")
    end
    it 'replaces colons with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO 9001:2015")).to eq("ISO_9001_2015")
    end
    it 'replaces slashes with underscores' do
      expect(exporter_instance.send(:sanitize_filename, "ISO/IEC 27001")).to eq("ISO_IEC_27001")
    end
    it 'replaces dots with underscores' do # Corrected expectation
      expect(exporter_instance.send(:sanitize_filename, "01.020.30")).to eq("01_020_30")
    end
    it 'replaces multiple invalid chars with single underscores and removes trailing underscore' do # Corrected expectation
      expect(exporter_instance.send(:sanitize_filename, "File / : Name ? *")).to eq("File_Name")
    end
    it 'returns original string if no invalid characters' do
      expect(exporter_instance.send(:sanitize_filename, "ISO123")).to eq("ISO123")
    end
    it 'handles nil input gracefully' do
      expect(exporter_instance.send(:sanitize_filename, nil)).to eq("")
    end
     it 'removes leading underscores' do
      expect(exporter_instance.send(:sanitize_filename, "_File_Name")).to eq("File_Name")
    end
     it 'removes trailing underscores' do
      expect(exporter_instance.send(:sanitize_filename, "File_Name_")).to eq("File_Name")
    end
  end
end