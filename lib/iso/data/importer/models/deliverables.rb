# lib/iso/data/importer/models/deliverable.rb
require 'lutaml/model'

module Iso
  module Data
    module Importer
      module Models
        class Deliverable < Lutaml::Model::Serializable
          attribute :id, Lutaml::Model::Type::Integer
          attribute :deliverable_type, Lutaml::Model::Type::String
          attribute :supplement_type, Lutaml::Model::Type::String, optional: true
          attribute :reference, Lutaml::Model::Type::String
          attribute :publication_date, Lutaml::Model::Type::Date, optional: true
          attribute :edition, Lutaml::Model::Type::Integer, optional: true
          attribute :ics_code, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::String), optional: true
          attribute :owner_committee, Lutaml::Model::Type::String, optional: true # Will likely reference TechnicalCommittee model
          attribute :current_stage, Lutaml::Model::Type::Integer # Harmonized stage code
          attribute :replaces, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Integer), optional: true
          attribute :replaced_by, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Integer), optional: true
          attribute :languages, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::String), optional: true
          # For complex types like 'pages' and 'scope', Lutaml::Model might support nested models
          # or you might store them as Hash and process them in methods.
          # For now, let's use Hash, assuming Lutaml can handle it or we'll add custom parsing/serialization.
          attribute :pages, Lutaml::Model::Type::Hash, optional: true # e.g., {"en" => 47}
          attribute :scope, Lutaml::Model::Type::Hash, optional: true # e.g., {"en" => "description"}

          # Retaining from your example, mapping to new attribute names if needed
          # These might be redundant if covered by the above, or could be specific YAML output names
          # For example, if your YAML needs `docidentifier` instead of `reference`

          # Method to convert to a hash suitable for YAML export
          # Lutaml-model might provide a #to_h method that can be customized.
          # This example assumes you want specific keys in your YAML.
          def to_yaml_hash
            {
              "id" => id,
              "docidentifier" => reference, # Mapping 'reference' to 'docidentifier'
              "type" => deliverable_type,
              "supplement_type" => supplement_type,
              "publication_date" => publication_date&.to_s, # Ensure date is string for YAML
              "edition" => edition,
              "ics" => ics_code,
              "committee" => owner_committee,
              "stage" => current_stage,
              "replaces" => replaces,
              "replaced_by" => replaced_by,
              "languages" => languages,
              "pages" => pages,
              "scope" => scope
              # Add other fields as needed for YAML output
            }.compact # Remove nil values for cleaner YAML
          end
        end
      end
    end
  end
end