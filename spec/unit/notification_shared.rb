shared_examples_for "an Notification subclass" do
  describe "when assigning data for the device" do
    before { Rapns::Deprecation.stub(:warn) }

    it "calls MultiJson.dump when multi_json responds to :dump" do
      notification = notification_class.new
      MultiJson.stub(:respond_to?).with(:dump).and_return(true)
      MultiJson.should_receive(:dump).with(any_args())
      notification.send(data_setter, { :pirates => 1 })
    end

    it "calls MultiJson.encode when multi_json does not respond to :dump" do
      notification = notification_class.new
      MultiJson.stub(:respond_to?).with(:dump).and_return(false)
      MultiJson.should_receive(:encode).with(any_args())
      notification.send(data_setter, { :ninjas => 1 })
    end

    it "raises an ArgumentError if something other than a Hash is assigned" do
      expect do
        notification.send(data_setter, Array.new)
      end.to raise_error(ArgumentError, "must be a Hash")
    end

    it "encodes the given Hash as JSON" do
      notification.send(data_setter, { :hi => "mom" })
      notification.read_attribute(:data).should == "{\"hi\":\"mom\"}"
    end

    it "decodes the JSON when using the reader method" do
      notification.send(data_setter, { :hi => "mom" })
      notification.send(data_getter).should == {"hi" => "mom"}
    end

    if Rails::VERSION::STRING < '4'
      it 'warns if attributes_for_device is assigned via mass-assignment' do
        Rapns::Deprecation.should_receive(:warn).with(':attributes_for_device via mass-assignment is deprecated. Use :data or the attributes_for_device= instance method.')
        notification_class.new(:attributes_for_device => {:hi => 'mom'})
      end
    end

    describe 'scopes' do
      before do
        Timecop.freeze(Time.now)

        (@delivered_notification = notification_class.new(app: app, delivered: true, failed: false)).save!(validate: false)
        (@failed_notification = notification_class.new(app: app, delivered: false, failed: true)).save!(validate: false)
        (@new_notification = notification_class.new(app: app, delivered: false, failed: false)).save!(validate: false)
      end

      after do
        Timecop.return
      end

      describe '.completed' do
        it 'should return notifications that have been delivered or failed' do
          completed_notification_ids = Rapns::Notification.completed.map(&:id)

          completed_notification_ids.size.should == 2
          completed_notification_ids.should include(@delivered_notification.id, @failed_notification.id)
          completed_notification_ids.should_not include(@new_notification.id)
        end
      end

      describe '.created_before' do
        it 'should return notifications that were created before the specified date' do
          @delivered_notification.created_at = Time.now - 30.days - 1.second
          @delivered_notification.save!(validate: false)

          notification_ids = Rapns::Notification.created_before(Time.now - 30.days).map(&:id)

          notification_ids.size.should == 1
          notification_ids.should include(@delivered_notification.id)
        end
      end

      describe '.completed_and_older_than' do
        before do
          @delivered_notification.created_at = Time.now - 30.days - 1.second
          @delivered_notification.save!(validate: false)

          @failed_notification.created_at = Time.now - 20.days - 1.second
          @failed_notification.save!(validate: false)

          @new_notification.created_at = Time.now - 30.days - 1.second
          @new_notification.save!(validate: false)
        end

        it 'should only include completed notifications' do
          notification_ids = Rapns::Notification.completed_and_older_than(Time.now - 30.days).map(&:id)

          notification_ids.size.should == 1
          notification_ids.should include(@delivered_notification.id)
        end

        it 'should not include completed notifications if not older than specified date' do
          notification_ids = Rapns::Notification.completed_and_older_than(Time.now - 30.days).map(&:id)

          notification_ids.size.should == 1
          notification_ids.should_not include(@failed_notification.id)
        end

        it 'should return notifications that are completed and created before the specified date' do
          notification_ids = Rapns::Notification.completed_and_older_than(Time.now - 20.days).map(&:id)

          notification_ids.size.should == 2
          notification_ids.should include(@delivered_notification.id, @failed_notification.id)
        end
      end
    end
  end
end
