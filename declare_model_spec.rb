require "spec_helper"

class Event
  include MyMongoid::Document
end

describe "MyMongoid Version:" do
  it "is a string" do
    expect(MyMongoid::VERSION).to be_a(String)
  end
end

describe "Document modules:" do
  it "creates MyMongoid::Document" do
    expect(MyMongoid::Document).to be_a(Module)
  end

  it "creates MyMongoid::Document::ClassMethods" do
    expect(MyMongoid::Document::ClassMethods).to be_a(Module)
  end
end

describe "Create a model:" do
  describe Event do
    it "is a mongoid model" do
      expect(Event.is_mongoid_model?).to eq(true)
    end
  end

  describe MyMongoid do
    it "maintains a list of models" do
      expect(MyMongoid.models).to include(Event)
    end
  end
end

describe "Instantiate a model:" do
  let(:attributes) {
    {"id" => "123", "public" => true}
  }

  let(:event) {
    Event.new(attributes)
  }

  it "can instantiate a model with attributes" do
    expect(event).to be_an(Event)
  end

  it "throws an error if attributes it not a Hash" do
    expect {
      Event.new(100)
    }.to raise_error(ArgumentError)
  end

  it "can read the attributes of model" do
    expect(event.attributes).to eq(attributes)
  end

  it "can get an attribute with #read_attribute" do
    expect(event.read_attribute("id")).to eq("123")
  end

  it "can set an attribute with #write_attribute" do
    event.write_attribute("id","234")
    expect(event.read_attribute("id")).to eq("234")
  end

  it "is a new record initially" do
    expect(event).to be_new_record
  end
end