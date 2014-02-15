require "spec_helper"

class Event
  include MyMongoid::Document
end

describe MyMongoid::Document do
  it "is a module" do
    expect(MyMongoid::Document).to be_a(Module)
  end
end

describe MyMongoid::Document::ClassMethods do
  it "is a module" do
    expect(MyMongoid::Document::ClassMethods).to be_a(Module)
  end
end

describe Event do
  it "is a mongoid model" do
    expect(Event.is_mongoid_model?).to eq(true)
  end
end

describe MyMongoid do
  it "maintains a list of models" do
    expect(MyMongoid.models).to include(Event)
  end

  it "has a version string" do
    expect(MyMongoid::VERSION).to be_a(String)
  end
end

