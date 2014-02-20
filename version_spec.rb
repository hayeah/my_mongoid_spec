require "spec_helper"

describe "MyMongoid Version:" do
  it "is a string" do
    expect(MyMongoid::VERSION).to be_a(String)
  end
end