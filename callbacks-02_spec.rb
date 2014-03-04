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



  describe "run before callbacks recursively" do
    let(:klass) {
      Class.new(base) {
        set_callback :save, :before, :before_1
        set_callback :save, :before, :before_2
      }
    }

    let(:target) {
      klass.new
    }

    after {
      target.save
    }

    it "should recursively call _invoke" do
      expect(target._save_callbacks).to receive(:_invoke).and_call_original.exactly(3).times
    end

    it "should call the before methods in order" do
      expect(target).to receive(:before_1).ordered
      expect(target).to receive(:before_2).ordered
      expect(target).to receive(:_save).ordered
    end
  end

  describe "run after callbacks recursively" do
    let(:klass) {
      Class.new(base) {
        set_callback :save, :after, :after_1
        set_callback :save, :after, :after_2
      }
    }

    let(:target) {
      klass.new
    }

    after {
      target.save
    }

    it "should call the after methods in order" do
      expect(target).to receive(:_save).ordered
      expect(target).to receive(:after_2).ordered
      expect(target).to receive(:after_1).ordered
    end

  end

  describe "run around callbacks recursively" do
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

    let(:target) {
      klass.new
    }

    after {
      target.save
    }

    it "should call the around methods in order" do
      expect(target).to receive(:around_1).and_call_original.ordered
      expect(target).to receive(:around_1_top).ordered
      expect(target).to receive(:around_2).and_call_original.ordered
      expect(target).to receive(:around_2_top).ordered
      expect(target).to receive(:_save).ordered
      expect(target).to receive(:around_2_bottom).ordered
      expect(target).to receive(:around_1_bottom).ordered
    end
  end
end