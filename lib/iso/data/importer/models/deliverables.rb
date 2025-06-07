# lib/iso/data/importer/models/deliverable.rb
require 'lutaml/model' # Check if this is the correct require for lutaml-model

module Iso
  module Data
    module Importer
      module Models
        class Deliverable < Lutaml::Model::Serializable # Or whatever base class lutaml-model provides
          # Define attributes based on ISO Deliverables Data Model
          # and how you want to name them internally.
          # Lutaml-model might have ways to map JSON keys if they differ.

          attribute :document_id, Lutaml::Model::Type::String
          attribute :reference, Lutaml::Model::Type::String
          attribute :title_en, Lutaml::Model::Type::String
          attribute :title_fr, Lutaml::Model::Type::String, optional: true # Example if optional
          attribute :publication_date, Lutaml::Model::Type::Date, optional: true # Lutaml might have a Date type
          attribute :edition, Lutaml::Model::Type::String, optional: true
          attribute :current_stage_code, Lutaml::Model::Type::String, optional: true
          # For arrays, lutaml-model has specific syntax, e.g.,
          # attribute :ics_codes, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::String), optional: true
          attribute :technical_committee_ref, Lutaml::Model::Type::String, optional: true
          attribute :type, Lutaml::Model::Type::String # e.g., IS, TS, TR
          attribute :status, Lutaml::Model::Type::String # e.g., published, withdrawn
          attribute :abstract_en, Lutaml::Model::Type::String, optional: true

          # You might still want to store the raw data for debugging or future fields
          attribute :raw_data, Lutaml::Model::Type::Hash, optional: true

          # Lutaml-model might handle to_h or to_yaml_hash for you,
          # or you might override it to customize the output structure.
          def to_yaml_hash
            # Convert self to a hash, potentially filtering/transforming fields
            # for YAML output. Lutaml-model might provide a #to_h method.
            to_h.compact # .compact to remove nil values if desired for YAML
          end
        end
      end
    end
  end
end