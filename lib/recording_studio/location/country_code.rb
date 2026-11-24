# frozen_string_literal: true

module RecordingStudio
  module Location
    # Country code shape and membership. Blank is allowed. A code already
    # stored is checked again only when that field changes.
    module CountryCode
      extend ActiveSupport::Concern

      ISO_COUNTRY_CODE = /\A[A-Z]{2}\z/

      included do
        if respond_to?(:validates)
          after_initialize :remember_kept_country_code
          validates :country_code,
                    format: {
                      with: ISO_COUNTRY_CODE,
                      message: ->(*) { RecordingStudioLocation::Copy.country_code_iso }
                    },
                    allow_blank: true
          validates :country_code,
                    inclusion: {
                      in: ->(_) { Countries::NAMES.keys },
                      message: ->(*) { RecordingStudioLocation::Copy.country_code_not_in_list }
                    },
                    if: :country_code_must_be_listed?
        end
      end

      private

      # A saved row is copied with every column marked changed from nil.
      # Keep the copied code until the caller sets a different one.
      def remember_kept_country_code
        return if new_record?

        @kept_country_code = country_code
        @country_code_was_kept = true
      end

      def country_code_must_be_listed?
        return false unless country_code.to_s.match?(ISO_COUNTRY_CODE)
        return true unless @country_code_was_kept

        country_code != @kept_country_code
      end
    end
  end
end
