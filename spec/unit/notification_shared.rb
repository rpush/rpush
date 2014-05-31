shared_examples_for "an Notification subclass" do
  describe "when assigning data for the device" do
    before { Rpush::Deprecation.stub(:warn) }

    it "calls MultiJson.dump when multi_json responds to :dump" do
      notification = notification_class.new
      MultiJson.stub(:respond_to?).with(:dump).and_return(true)
      MultiJson.should_receive(:dump).with(any_args)
      notification.data = { pirates: 1 }
    end

    it "calls MultiJson.encode when multi_json does not respond to :dump" do
      notification = notification_class.new
      MultiJson.stub(:respond_to?).with(:dump).and_return(false)
      MultiJson.should_receive(:encode).with(any_args)
      notification.data = { ninjas: 1 }
    end

    it "raises an ArgumentError if something other than a Hash is assigned" do
      expect do
        notification.data = Array.new
      end.to raise_error(ArgumentError, "must be a Hash")
    end

    it "encodes the given Hash as JSON" do
      notification.data = { hi: "mom" }
      notification.read_attribute(:data).should eq("{\"hi\":\"mom\"}")
    end

    it "decodes the JSON when using the reader method" do
      notification.data = { hi: "mom" }
      notification.data.should eq("hi" => "mom")
    end
  end
end
