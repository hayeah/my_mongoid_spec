require "spec_helper"

def config_db
  MyMongoid.configure do |config|
    config.host = "127.0.0.1:27017"
    config.database = "my_mongoid_test"
  end
end

def clean_db
  Event.collection.drop
end

class Event
  include MyMongoid::Document
  field :a
  field :b
end

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
    config_db
  }

  before(:each) {
    # remove memoized session before each test
    MyMongoid.send(:remove_instance_variable, :@session) if MyMongoid.instance_variable_defined?(:@session)
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

describe "Should be able to create a record:" do
  before(:all) { config_db }
  before { clean_db }

  describe "model collection:" do
    describe "Model.collection_name" do
      it "should use active support's titleize method" do
        expect(Event.collection_name).to eq("events")
      end
    end

    describe "Model.collection" do
      it "should return a model's collection" do
        expect(Event.collection).to be_a(Moped::Collection)
        expect(Event.collection.name).to eq("events")
      end
    end
  end


  describe "#to_document" do

    let(:event) {
      Event.new({"a" => 10, "b" => 20})
    }

    it "should be a bson document" do
      expect(event.to_document).to eq(event.attributes)
      expect(event.to_document.to_bson).to be_a(String)
    end
  end

  describe "Model#save" do
    let(:attrs) {
      {"id" => "1", "a" => 10, "b" => 20}
    }

    let(:event) {
      Event.new(attrs)
    }

    context "successful insert:" do
      before do
        @result = event.save
      end

      it "should insert a new record into the db" do
        expect(Event.collection.find().count).to eq(1)
      end

      it "should return true" do
        expect(@result).to eq(true)
      end

      it "should make Model#new_record return false" do
        expect(event).to_not be_new_record
      end
    end
  end

  describe "Model.create" do
    let(:attrs) {
      {"_id" => "1", "a" => 10, "b" => 20}
    }

    def create_event
      Event.create(attrs)
    end

    before do
      @event = create_event
    end

    it "should return a saved record" do
      expect(@event).to be_an(Event)
      expect(@event).to_not be_new_record
      expect(@event.attributes).to eq(attrs)
    end
  end

  context "saving a record with no id" do
    let(:event) {
      Event.new({"a" => 10})
    }

    before do
      event.save
    end

    it "should generate a random id" do
      expect(event.id).to be_a(BSON::ObjectId)
      expect(Event.collection.find({"_id" => event.id}).count).to eq(1)
    end
  end
end

describe "Should be able to find a record:" do
  describe "Model.instantiate" do
    let(:model) {
      Class.new do
        include MyMongoid::Document
        field :a
        field :b

        def a=(val)
          raise "should not use attribute setter"
        end
      end
    }

    let(:attrs) {
      {"_id" => "1", "a" => 10, "b" => 20}
    }

    let(:event) {
      model.instantiate(attrs)
    }

    it "should return a model instance" do
      expect(event).to be_an(model)
    end

    it "should return an instance that's not a new_record" do
      expect(event).to_not be_new_record
    end

    it "should have the given attributes" do
      expect(event.attributes).to eq(attrs)
    end
  end

  describe "Model.find" do
    let(:attrs) {
      {"_id" => "1", "a" => 10, "b" => 20}
    }

    before(:all) {
      config_db
    }

    before {
      clean_db
      Event.create(attrs)
    }

    it "should be able to find a record by issuing query" do
      event = Event.find("_id" => "1")
      expect(event).to be_a(Event)
      expect(event.attributes).to eq(attrs)
    end

    it "should be able to find a record by issuing shorthand id query" do
      event = Event.find("1")
      expect(event).to be_a(Event)
      expect(event.attributes).to eq(attrs)
    end

    it "should raise Mongoid::RecordNotFoundError if nothing is found for an id" do
      expect {
        Event.find("_id" => "unknown")
      }.to raise_error(MyMongoid::RecordNotFoundError)
    end

  end
end

describe "Should track changes made to a record" do
  let(:event) {
    Event.instantiate({"a" => 1, "b" => 2})
  }

  describe "#changed_attributes" do


    it "should be an empty hash for an newly instantiated record (from Model.instantiate)" do
      expect(event.changed_attributes).to eq({})
    end

    it "should track writes to attributes" do
      event.a = 10
      event.write_attribute("b",20)
      expect(event.changed_attributes.keys).to include("a","b")
    end

    it "should keep the original attribute values" do
      event.a = 10
      expect(event.changed_attributes["a"]).to eq(1)
      event.write_attribute("b",20)
      expect(event.changed_attributes["b"]).to eq(2)
    end

    it "should not make a field dirty if the assigned value is equaled to the old value" do
      event.a = 1
      expect(event.changed_attributes).to be_empty
    end
  end

  describe "#changed?" do
    it "should be false for a newly instantiated record" do
      expect(event).to_not be_changed
    end

    it "should be true if a field changed" do
      event.a = 20
      expect(event).to be_changed
    end
  end
end

describe "Should be able to update a record:" do

  before {
    config_db
    clean_db
  }

  describe "#atomic_updates" do
    let(:event) {
      Event.instantiate({"a" => 1, "b" => 2})
    }

    it "should return {} if nothing changed" do
      expect(event.atomic_updates).to be_empty
    end

    it "should return {} if record is not a persisted document" do
      event = Event.new({"a" => 1})
      expect(event.atomic_updates).to be_empty
    end

    it "should generate the $set update operation to update a persisted document" do
      event.a = 10
      event.b = 20
      set = event.atomic_updates["$set"]
      expect(set).to be_an(Hash)
      expect(set).to eq({"a" => 10, "b" => 20})
    end
  end

  describe "updating database:" do
    let(:attrs) {
      {"_id" => "1", "a" => 1, "b" => 2}
    }

    let(:event) {
      Event.create(attrs)
    }

    let(:event2) {
      Event.find("1")
    }

    describe "#save" do
      it "should have no changes right after persisting" do
        expect(event).to_not be_changed
      end
    end

    describe "#update_document" do
      it "should not issue query if nothing changed" do
        expect_any_instance_of(Moped::Query).to_not receive(:update)
        event.update_document
        expect(event2.attributes).to eq(attrs)
      end

      it "should update the document in database if there are changes" do
        event.a = 10
        event.update_document
        expect(event2.a).to eq(10)
      end
    end

    describe "#save" do
      it "should save the changes if a document is already persisted" do
        event.a = 10
        event.save
        expect(event2.a).to eq(10)
      end
    end

    describe "#update_attributes" do
      it "should change and persiste attributes of a record" do
        event.update_attributes "a" => 10, "b" => 20
        expect(event2.a).to eq(10)
        expect(event2.b).to eq(20)
      end
    end
  end
end

describe "Should be able to delete a record:" do
  let(:attrs) {
    {"_id" => "1", "a" => 1, "b" => 2}
  }

  let(:event) {
    Event.find("1")
  }

  before {
    config_db
    clean_db
    Event.create(attrs)
  }

  describe "#delete" do
    before {
      event.delete
    }
    it "should delete a record from db" do
      expect {
        Event.find("1")
      }.to raise_error(MyMongoid::RecordNotFoundError)
    end

    it "should return true for deleted?" do
      expect(event).to be_deleted
    end
  end

end
