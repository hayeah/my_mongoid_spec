require "active_support"

class Account
  attr_reader :balance
  def initialize(balance)
    @balance = balance
  end

  def deposit(amount)
    @balance += amount
  end

  def withdraw(amount)
    @balance -= amount
  end

  def valid_access?
    true
  end
end

class ATM
  attr_reader :account
  def initialize(account)
    @account = account
  end
end

module ATM::Commands
  def withdraw(amount)
    account.withdraw(amount)
    -amount
  end

  def deposit(amount)
    account.deposit(amount)
    amount
  end
end

module ATM::Authentication
  extend ActiveSupport::Concern

  def valid_access?
    @account.valid_access?
  end
end

module ATM::Logging
  extend ActiveSupport::Concern

  def log(msg)
    puts msg
  end
end

module ATM::SMSNotification
  extend ActiveSupport::Concern

  def send_sms(msg)
    # fake send
  end
end

module ATM::Concerns
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks
    include ATM::Commands
    include ATM::Authentication
    include ATM::Logging
    include ATM::SMSNotification

    alias :_withdraw :withdraw
    alias :_deposit :deposit

    define_callbacks(:command, :terminator => "result == false", :skip_after_callbacks_if_terminated => true)
    set_callback(:command, :before, :valid_access?)
    set_callback :command, :before do
      log("before: #{@account.balance}")
    end
    set_callback :command, :after do
      send_sms("your new balance is #{@account.balance}")
    end
    set_callback :command, :after do
      log("after: #{@account.balance}")
    end

    def withdraw(amount)
      run_callbacks :command do
        _withdraw(amount)
      end
    end

    def deposit(amount)
      run_callbacks :command do
        _deposit(amount)
      end
    end
  end
end

ATM.send(:include, ATM::Concerns)
