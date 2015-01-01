require 'spec_helper'

describe Pushmeup do



  describe "APNS" do
    let(:apns) {Pushmeup::APNS::Gateway.new}

    it "should not forget the APNS default parameters" do
      apns.host.should == "gateway.sandbox.push.apple.com"
      apns.port.should == 2195
      apns.pem.should be_equal(nil)
      apns.pass.should be_equal(nil)
    end

    describe "Notifications" do

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = Pushmeup::APNS::Notification.new("123", {:alert => "hi"})
          b = Pushmeup::APNS::Notification.new("123", {:alert => "hi"})
          a.should eq(b)
        end

      end

    end

  end

  describe "GCM" do
    let(:gcm) {Pushmeup::APNS::Gateway.new}

    describe "Notifications" do

      before do
        @options = {:data => "dummy data"}
      end

      it "should allow only notifications with device_tokens as array" do
        n = Pushmeup::GCM::Notification.new("id", @options)
        n.device_tokens.is_a?(Array).should be_true

        n.device_tokens = ["a" "b", "c"]
        n.device_tokens.is_a?(Array).should be_true

        n.device_tokens = "a"
        n.device_tokens.is_a?(Array).should be_true
      end

      it "should allow only notifications with data as hash with :data root" do
        n = Pushmeup::GCM::Notification.new("id", { :data => "data" })

        n.data.is_a?(Hash).should be_true
        n.data.should == {:data => "data"}

        n.data = {:a => ["a", "b", "c"]}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => ["a", "b", "c"]}

        n.data = {:a => "a"}
        n.data.is_a?(Hash).should be_true
        n.data.should == {:a => "a"}
      end

      describe "#==" do

        it "should properly equate objects without caring about object identity" do
          a = Pushmeup::GCM::Notification.new("id", { :data => "data" })
          b = Pushmeup::GCM::Notification.new("id", { :data => "data" })
          a.should eq(b)
        end

      end

    end
  end
end
