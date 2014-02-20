require "spec_helper"

describe "Should be able to configure MyMongoid:" do
  describe "MyMongoid::Configuration" do
    let(:config) {
      MyMongoid::Configuration.instance
    }

    it "should be a singleton class" do
      expect(MyMongoid::Configuration.included_modules).to include(Singleton)
    end

    it "should have #host accessor" do
      expect(config).to respond_to(:host)
      expect(config).to respond_to(:host=)
    end

    it "should have #database accessor" do
      expect(config).to respond_to(:database)
      expect(config).to respond_to(:database=)
    end
  end

  describe "MyMongoid.configuration" do
    it "should return the MyMongoid::Configuration singleton" do
      expect(MyMongoid.configuration).to be_a(MyMongoid::Configuration)
      expect(MyMongoid.configuration).to eq(MyMongoid::Configuration.instance)
    end
  end

  describe "MyMongoid.configure" do
    it "should yield MyMongoid.configuration to a block" do
      expect { |b|
        MyMongoid.configure(&b)
      }.to yield_control

      MyMongoid.configure do |config|
        expect(config).to eq(MyMongoid.configuration)
      end
    end
  end
end

describe "Should be able to get database session:" do
  before(:all) {
    MyMongoid.configure do |config|
      config.host = "127.0.0.1:27017"
      config.database = "my_mongoid_test"
    end
  }

  before(:each) {
    # remove memoized session before each test
    MyMongoid.remove_instance_variable(:@session) if MyMongoid.instance_variable_defined?(:@session)
  }

  describe "MyMongoid.session" do
    it "should return a Moped::Session" do
      expect(MyMongoid.session).to be_a(Moped::Session)
    end

    it "should memoize the session @session" do
      MyMongoid.session
      expect(MyMongoid.session).to eq(MyMongoid.instance_variable_get(:@session))
    end

    it "should raise MyMongoid::UnconfiguredDatabaseError if host and database are not configured" do
      config = MyMongoid.configuration
      config.host = nil
      config.database = nil
      expect {
        MyMongoid.session
      }.to raise_error(MyMongoid::UnconfiguredDatabaseError)
    end
  end
end