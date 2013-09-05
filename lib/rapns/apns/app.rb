module Rapns
  module Apns
    class App < Rapns::App
      validates :environment, :presence => true, :inclusion => { :in => %w(development production sandbox) }
      validates :certificate, :presence => true
      validate :certificate_has_matching_private_key

      private

      def certificate_has_matching_private_key
        result = false
        if certificate.present?
          x509 = OpenSSL::X509::Certificate.new(certificate) rescue nil
          pkey = OpenSSL::PKey::RSA.new(certificate, password) rescue nil
          result = !x509.nil? && !pkey.nil?
          unless result
            errors.add :certificate, 'Certificate value must contain a certificate and a private key.'
          end
        end
        result
      end
    end
  end
end
