module Rapns
  module Wpns
    class Notification < Rapns::Notification
      validates :uri, :presence => true
      validates_with Rapns::Wpns::DataValidator
      
      def registration_ids=(ids)
        ids = [ids] if ids && !ids.is_a(Array)
        super
      end

      def as_json
        json = {
          'data' => data
        }

        if collapse_key
          json['consolidationKey'] = collapse_key
        end

        json
      end

    end
  end
end
