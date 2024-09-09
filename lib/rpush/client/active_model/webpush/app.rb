# frozen_string_literal: true

module Rpush
  module Client
    module ActiveModel
      module Webpush
        module App
          class VapidKeypairValidator < ::ActiveModel::Validator
            def validate(record)
              return if record.vapid_keypair.blank?

              keypair = record.vapid
              %i[subject public_key private_key].each do |key|
                record.errors.add(:vapid_keypair, "must have a #{key} entry") unless keypair.key?(key)
              end
            rescue StandardError
              record.errors.add(:vapid_keypair, 'must be valid JSON')
            end
          end

          def self.included(base)
            base.class_eval do
              alias_attribute :vapid_keypair, :certificate
              validates :vapid_keypair, presence: true
              validates_with VapidKeypairValidator
            end
          end

          def service_name
            'webpush'
          end

          def vapid
            @vapid ||= JSON.parse(vapid_keypair).symbolize_keys
          end
        end
      end
    end
  end
end
