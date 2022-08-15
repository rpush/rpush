class Fixtures
  def self.build(fixture_name, attrs = {})
    send("build_#{fixture_name}", attrs)
  end

  def self.create!(fixture_name, attrs = {})
    obj = build(fixture_name, attrs)
    obj.save! && obj
  end

  def self.build_hms_notification(attrs)
    attrs ||= {}
    Rpush::Hms::Notification.new(
      app_id: 1,
      title: 'title',
      body: 'body',
      **attrs
    ).tap do |notif|
      notif.click_action = {
        "type" => 3
      }
    end
  end

  def self.build_hms_app(attrs)
    attrs ||= {}
    Rpush::Hms::App.new(
      hms_app_id: 'hms_app_id',
      hms_key_id: 'hms_key_id',
      hms_sub_acc_id: 'hms_sub_acc_id',
      hms_key: 'hms_key',
      name: 'hms',
      **attrs
    )
  end
end
