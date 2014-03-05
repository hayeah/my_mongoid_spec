require "spec_helper"

describe MyMongoid::MyCallbacks do
  let(:base) {
    Class.new do
      include MyMongoid::MyCallbacks

      define_callbacks :save

      def before_1
      end

      def before_2
      end

      def save
        run_callbacks(:save) {
          _save
        }
      end

      def _save
      end

      def to_s
        "#<Foo #{object_id}>"
      end
    end
  }

  describe "Callback#compile" do
    let(:klass) {
      Class.new(base) do
        def callback_method
          yield if block_given?
        end

        def method_in_block
        end
      end
    }

    let(:callback) {
      MyMongoid::MyCallbacks::Callback.new(:callback_method,:before)
    }

    let(:target) {
      klass.new
    }

    after do
      lambda = callback.compile
      lambda.call(target) do
        target.method_in_block
      end
    end

    it "should invoke the callback method" do
      expect(target).to receive(:callback_method)
    end

    it "should invoke the callback method with a block if given one" do
      expect(target).to receive(:method_in_block)
    end
  end

  describe "compile before callbacks recursively" do
    let(:klass) {
      Class.new(base) {
        set_callback :save, :before, :before_1
        set_callback :save, :before, :before_2
      }
    }

    let(:callback_chain) {
      klass._save_callbacks
    }

    let(:target) {
      klass.new
    }

    it "should return a lambda" do
      expect(callback_chain.compile).to be_a(Proc)
    end

    it "should recursively call _compile" do
      expect(callback_chain).to receive(:_compile).and_call_original.exactly(3).times
      callback_chain.compile
    end

    it "should call the before methods in order when compiled lambda is run" do
      expect(target).to receive(:before_1).ordered
      expect(target).to receive(:before_2).ordered
      expect(target).to receive(:_save).ordered

      lambda = callback_chain.compile
      lambda.call(target) do
        target._save
      end
    end
  end

  describe "CallbackChain#compile memoize" do
    let(:klass) {
      Class.new(base)
    }

    let(:callback_chain) {
      klass._save_callbacks
    }

    it "should memoize the compiled callback chain" do
      fn1 = callback_chain.compile
      fn2 = callback_chain.compile
      expect(fn1).to eq(fn2)
    end

    it "should reset memoization if a new callback is added" do
      fn1 = callback_chain.compile
      klass.set_callback :save, :before, :before_method
      fn2 = callback_chain.compile
      expect(fn1).to_not eq(fn2)
    end
  end

  describe "compile around callbacks recursively" do
    let(:klass) {
      Class.new(base) {
        set_callback :save, :around, :around_1
        set_callback :save, :around, :around_2

        def around_1
          around_1_top
          yield
          around_1_bottom
        end

        def around_2
          around_2_top
          yield
          around_2_bottom
        end
      }
    }

    let(:callback_chain) {
      klass._save_callbacks
    }

    let(:target) {
      klass.new
    }

    it "should call the around methods in order when compiled lambda is run" do
      expect(target).to receive(:around_1).and_call_original.ordered
      expect(target).to receive(:around_1_top).ordered
      expect(target).to receive(:around_2).and_call_original.ordered
      expect(target).to receive(:around_2_top).ordered
      expect(target).to receive(:_save).ordered
      expect(target).to receive(:around_2_bottom).ordered
      expect(target).to receive(:around_1_bottom).ordered

      lambda = callback_chain.compile
      lambda.call(target) do
        target._save
      end
    end
  end


  describe "compile after callbacks recursively" do
    let(:klass) {
      Class.new(base) {
        set_callback :save, :after, :after_1
        set_callback :save, :after, :after_2
      }
    }

    let(:callback_chain) {
      klass._save_callbacks
    }

    let(:target) {
      klass.new
    }

    it "should call the after methods in order" do
      expect(target).to receive(:_save).ordered
      expect(target).to receive(:after_2).ordered
      expect(target).to receive(:after_1).ordered

      lambda = callback_chain.compile
      lambda.call(target) do
        target._save
      end
    end
  end

  describe "run_callbacks should use the compiled lambda to run callbacks" do
    let(:klass) {
      Class.new(base) do
        set_callback :save, :after, :after_1
        set_callback :save, :around, :around_1
        set_callback :save, :before, :before_1

        def around_1
          around_top
          yield
          around_bottom
        end

        def before_1
        end

        def after_1
        end

        def around_top
        end

        def around_bottom
        end
      end
    }

    let(:target) {
      klass.new
    }

    let(:callback_chain) {
      klass._save_callbacks
    }

    it "should invoke #compile" do
      expect(callback_chain).to receive(:compile).and_call_original
      target.save
    end

    it "should run callback methods" do
      expect(target).to receive(:before_1).and_call_original.ordered
      expect(target).to receive(:around_1).and_call_original.ordered
      expect(target).to receive(:around_top).ordered
      expect(target).to receive(:_save).ordered
      expect(target).to receive(:around_bottom).ordered
      expect(target).to receive(:after_1).and_call_original.ordered

      target.save
    end
  end
end