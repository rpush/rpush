module Rapns
  class PemError < Exception; end

  module Daemon
    class Pem
      def self.load(environment, pem_path)
        @pem = read_pem(environment, pem_path)
      end

      def self.pem
        @pem
      end

      protected

      def self.read_pem(environment, pem_path)
        if !File.exists?(pem_path)
          raise PemError, "#{pem_path} does not exist. Your .pem file must match the Rails environment '#{environment}'."
        else
          File.read(pem_path)
        end
      end

    end
  end
end