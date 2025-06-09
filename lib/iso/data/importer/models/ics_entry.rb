# lib/iso/data/importer/models/ics_entry.rb
require 'lutaml/model'

module Iso
  module Data
    module Importer
      module Models
        # Represents an International Classification for Standards (ICS) entry
        class IcsEntry < Lutaml::Model::Serializable
          attribute :identifier, Lutaml::Model::Type::String # e.g., "03.140"
          attribute :parent, Lutaml::Model::Type::String, optional: true # e.g., "03"
          attribute :title_en, Lutaml::Model::Type::String
          attribute :title_fr, Lutaml::Model::Type::String, optional: true
          attribute :scope_en, Lutaml::Model::Type::String, optional: true
          attribute :scope_fr, Lutaml::Model::Type::String, optional: true

          # 'references' seems to be a more complex nested structure.
          # For now, storing as an array of hashes. We might need a dedicated Reference model
          # if lutaml-model supports it easily or if we need more structured access.
          attribute :references, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Hash), optional: true
          # Example of a reference hash: { "identifier" => "01.080.10", "note" => "Information technology..." }

          # Method to convert to a hash suitable for YAML export
          def to_yaml_hash
            {
              "identifier" => identifier,
              "parent" => parent,
              "title_en" => title_en,
              "title_fr" => title_fr,
              "scope_en" => scope_en,
              "scope_fr" => scope_fr,
              "references" => references
            }.compact # Remove nil values for cleaner YAML
          end
        end
      end
    end
  end
end