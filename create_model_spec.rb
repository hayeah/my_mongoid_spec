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