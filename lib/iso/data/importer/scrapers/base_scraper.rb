# lib/iso/data/importer/scrapers/base_scraper.rb
# frozen_string_literal: true

require 'faraday'
require 'faraday/follow_redirects' # Ensure this is in your gemspec if used
require 'fileutils' # For mkdir_p

module Iso
  module Data
    module Importer
      module Scrapers
        # Base class for fetching and processing data files.
        class BaseScraper
          # Initializes the scraper, ensuring the temporary directory exists.
          def initialize
            FileUtils.mkdir_p("tmp")
          end

          # Fetches a file from a given URL and saves it to a specified output path.
          # @param url [String] The URL to fetch the file from.
          # @param output_path [String] The path to save the downloaded file.
          # @raise [Iso::Data::Importer::DownloadError] if the download fails.
          def fetch_file(url, output_path)
            log "Downloading from #{url} to #{output_path}..."
            conn = Faraday.new do |faraday|
              faraday.response :follow_redirects # Handle redirects
              faraday.adapter Faraday.default_adapter # Or :net_http or other
            end

            response = conn.get(url)

            if response.success?
              File.open(output_path, 'wb') do |file|
                file.write(response.body)
              end
              log "Successfully saved to #{output_path}"
            else
              error_message = "Failed to download #{url}. Status: #{response.status}, Body: #{response.body[0..500]}"
              log error_message, 1, :error
              raise Iso::Data::Importer::DownloadError, error_message
            end
          rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
            error_message = "Network error while downloading #{url}: #{e.message}"
            log error_message, 1, :error
            raise Iso::Data::Importer::DownloadError, error_message
          end

          # Log a message with indentation and optional type (info, error).
          # @param message [String] The message to log.
          # @param level [Integer] The indentation level (default: 0).
          # @param type [Symbol] :info or :error (default: :info).
          def log(message, level = 0, type = :info)
            indent = "  " * level
            prefix = type == :error ? "[ERROR] " : ""
            puts "#{indent}#{prefix}#{message}"
          end
        end
      end
    end
  end
end