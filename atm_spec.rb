require "atm"

describe ATM do
  let(:account) {
    Account.new(200)
  }

  let(:atm) {
    ATM.new(account)
  }

  describe "should declare callback hooks" do
    let(:klass) {
      Class.new(ATM)
    }

    let(:atm) {
      klass.new(account)
    }

    it "should be able to register a :command callback" do
      expect {
        klass.module_eval do
          set_callback :command, :foo
        end
      }.to_not raise_error
    end
  end

  describe "should run callbacks when #deposit or #withdraw is invoked" do
    it "should run the :command callbacks when #deposit is invoked" do
      expect(atm).to receive(:run_callbacks).with(:command)
      atm.deposit(100)
    end

    it "should run the :command callbacks when #withdraw is invoked" do
      expect(atm).to receive(:run_callbacks).with(:command)
      atm.withdraw(100)
    end
  end

  describe "logging concern" do
    it "should log around #deposit" do
      expect(atm).to receive(:log).ordered
      expect(account).to receive(:deposit).ordered
      expect(atm).to receive(:log).ordered
      atm.deposit(100)
    end
  end

  describe "text notification concern" do
    it "should invoke #send_sms after #deposit" do
      expect(account).to receive(:deposit).with(100).ordered
      expect(atm).to receive(:send_sms).ordered
      atm.deposit(100)
    end
  end

  describe "authentication concern" do
    after {
      atm.deposit(100)
    }

    context "account.valid_access? returns true" do
      it "should call Account#deposit" do
        expect(account).to receive(:deposit).with(100)
      end
    end

    context "account.valid_access? returns false" do
      before {
        allow(account).to receive(:valid_access?) { false }
      }

      it "should cancel #deposit" do
        expect(account).to_not receive(:deposit)
      end

      it "should cancel after callbacks" do
        expect(account).to_not receive(:send_sms)
      end
    end
  end
end
