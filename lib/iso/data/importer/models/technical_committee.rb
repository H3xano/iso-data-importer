# lib/iso/data/importer/models/technical_committee.rb
require 'lutaml/model'

module Iso
  module Data
    module Importer
      module Models
        # Represents a Technical Committee (TC), Sub-Committee (SC), or Working Group (WG)
        class TechnicalCommittee < Lutaml::Model::Serializable
          attribute :id, Lutaml::Model::Type::Integer
          attribute :reference, Lutaml::Model::Type::String
          attribute :status, Lutaml::Model::Type::String # "Active" or "Suspended"
          attribute :title, Lutaml::Model::Type::Hash # e.g., {"en" => "Quantum technologies"}
          attribute :secretariat, Lutaml::Model::Type::Hash # e.g., {"id" => 2101, "acronym" => "SIS"}
          attribute :creation_date, Lutaml::Model::Type::Date, optional: true
          attribute :scope, Lutaml::Model::Type::Hash, optional: true # e.g., {"en" => "Standardization of..."}
          attribute :parent_id, Lutaml::Model::Type::Integer, optional: true
          attribute :children_id, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Integer), optional: true
          attribute :p_members, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Hash), optional: true # Array of hashes like {"id"=>1511,"acronym"=>"DIN"}
          attribute :o_members, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Hash), optional: true # Array of hashes
          attribute :committee_liaisons, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Hash), optional: true # Array of hashes like {"id"=>620986,"reference"=>"ISO/TC 261"}
          attribute :organization_liaisons, Lutaml::Model::Type::Array.of(Lutaml::Model::Type::Hash), optional: true # Array of hashes
          attribute :sort_key, Lutaml::Model::Type::String, optional: true

          # Method to convert to a hash suitable for YAML export
          def to_yaml_hash
            {
              "id" => id,
              "reference" => reference,
              "status" => status,
              "title" => title,
              "secretariat" => secretariat,
              "creation_date" => creation_date&.to_s,
              "scope" => scope,
              "parent_id" => parent_id,
              "children_id" => children_id,
              "p_members" => p_members,
              "o_members" => o_members,
              "committee_liaisons" => committee_liaisons,
              "organization_liaisons" => organization_liaisons,
              "sort_key" => sort_key
            }.compact # Remove nil values for cleaner YAML
          end
        end
      end
    end
  end
end