module Rapns
  class CertificateError < StandardError; end

  module Daemon
    class Certificate
      attr_accessor :certificate

      def initialize(certificate_path)
        @certificate_path = certificate_path
      end

      def load
        @certificate = read_certificate
      end

      protected

      def read_certificate
        if !File.exists?(@certificate_path)
          raise CertificateError, "#{@certificate_path} does not exist. The certificate location can be configured in config/rapns/rapns.yml."
        else
          File.read(@certificate_path)
        end
      end
    end
  end
end