module Rapns
  class AppPresenceValidator < ActiveModel::Validator
    def validate(record)
      if record.app.size < 1
        record.errors[:app] << "at least one app required."
      end
    end
  end
end