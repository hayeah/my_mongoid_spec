require "spec_helper"

describe MyMongoid::MyCallbacks do
  let(:base) {
    Class.new do
      include MyMongoid::MyCallbacks
    end
  }

  describe ".define_callbacks"  do
    let(:klass) {
      Class.new(base) do
        define_callbacks :save
      end
    }

    it "should declare the class attribute \#{name}_callbacks" do
      expect(klass).to respond_to("_save_callbacks")
      expect(klass).to respond_to("_save_callbacks=")
    end

    it "should initially return an instance of CallbackChain" do
      expect(klass._save_callbacks).to be_a(MyMongoid::MyCallbacks::CallbackChain)
    end
  end

  describe "MyMongoid::MyCallbacks::Callback" do
    let(:cb) {
      MyMongoid::MyCallbacks::Callback.new(:before_save,:before)
    }

    let(:target) {
      double()
    }

    it "should have the #kind attr_reader" do
      expect(cb.kind).to eq(:before)
    end

    it "should have the #filter attr_reader" do
      expect(cb.filter).to eq(:before_save)
    end

    it "should call the target object's method when #invoke is called" do
      expect(target).to receive(:before_save)
      cb.invoke(target)
    end
  end

  describe "MyMongoid::MyCallbacks::CallbackChain" do
    let(:cbchain) {
      MyMongoid::MyCallbacks::CallbackChain.new
    }

    let(:cb1) {
      double()
    }

    let(:cb2) {
      double()
    }

    it "should initially be empty" do
      expect(cbchain).to be_empty
    end

    it "should initially set @chain to be the empty array" do
      expect(cbchain.chain).to eq([])
    end

    it "should be able to append callbacks to the chain" do
      cbchain.append(cb1)
      cbchain.append(cb2)
      expect(cbchain.chain).to eq([cb1,cb2])
    end

    describe "#invoke" do
      let(:target) {
        double()
      }

      before {
        cbchain.append(cb1)
        cbchain.append(cb2)
      }

      after {
        cbchain.invoke(target) {
          target.main_method
        }
      }

      it "should call the callbacks in order, then call the block" do
        expect(cb1).to receive(:invoke).with(target).ordered
        expect(cb2).to receive(:invoke).with(target).ordered
        expect(target).to receive(:main_method)
      end
    end
  end

  describe ".set_callback" do
    let(:klass) {
      Class.new(base) do
        define_callbacks :save
        set_callback :save, :before, :before_save
      end
    }

    let(:callback) {
      klass._save_callbacks.chain.first
    }

    it "should append a callback to the named callback chain" do
      expect(callback).to be_a(MyMongoid::MyCallbacks::Callback)
      expect(callback.kind).to eq(:before)
      expect(callback.filter).to eq(:before_save)
    end
  end

  describe "#run_callbacks" do
    let(:klass) {
      Class.new(base) do
        define_callbacks :save
        set_callback :save, :before, :before_save
      end
    }

    let(:object) {
      klass.new
    }

    it "should invoke the callback chain" do
      expect(object).to receive(:before_save).ordered
      expect(object).to receive(:main_method).ordered
      object.run_callbacks(:save) do
        object.main_method
      end
    end
  end

end