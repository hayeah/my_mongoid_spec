require "spec_helper"

describe "Should define lifecycle callbacks" do
  def config_db
    MyMongoid.configure do |config|
      config.host = "127.0.0.1:27017"
      config.database = "my_mongoid_test"
    end
  end

  def clean_db
    klass.collection.drop
  end

  before {
    config_db
    clean_db
  }

  let(:base) {
    Class.new {
      include MyMongoid::Document

      def self.name
        self.to_s
      end

      def self.to_s
        "Event"
      end
    }
  }


  describe "all hooks:" do
    let(:klass) { base }
    [:delete,:save,:create,:update].each do |name|
      it "should declare before hook for #{name}" do
        expect(klass).to respond_to("before_#{name}")
      end

      it "should declare around hook for #{name}" do
        expect(klass).to respond_to("around_#{name}")
      end

      it "should declare after hook for #{name}" do
        expect(klass).to respond_to("after_#{name}")
      end
    end
  end

  describe "only before hooks:" do
    let(:klass) { base }
    [:find,:initialize].each do |name|
      it "should not declare before hook for #{name}" do
        expect(klass).to_not respond_to("before_#{name}")
      end

      it "should not declare around hook for #{name}" do
        expect(klass).to_not respond_to("around_#{name}")
      end

      it "should declare after hook for #{name}" do
        expect(klass).to respond_to("after_#{name}")
      end
    end
  end

  describe "run create callbacks" do
    let(:klass) {
      Class.new(base) {
        before_create :before_method
      }
    }

    let(:record) {
      klass.new({})
    }

    it "should run callbacks when saving a new record" do
      expect(record).to receive(:before_method)
      record.save
    end

    it "should run callbacks when creating a new record" do
      expect_any_instance_of(klass).to receive(:before_method)
      klass.create({})
    end
  end

  describe "run save callbacks" do
    let(:klass) {
      Class.new(base) {
        before_save :before_method
        def before_method
        end
      }
    }

    it "should run callbacks when saving a new record" do
      record = klass.new({})
      expect(record).to receive(:before_method)
      record.save
    end

    it "should run callbacks when saving a persisted record" do
      record = klass.create({})
      expect(record).to receive(:before_method)
      record.save
    end

  end

end