require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < Test::Unit::TestCase
  context "An Account" do
    setup do
      @account = Account.new
    end
    
    should "require a name" do
      @account.name = ''
      @account.domain = 'test'
      assert !@account.valid?
      assert_equal "can't be blank", @account.errors[:name]
    end
    
    should "not allow 'a test' as a domain" do
      @account.name = 'A test'
      @account.domain = 'a test'
      assert !@account.valid?
    end
    
    should "allow 'test' as a domain" do
      @account.name = 'Test'
      @account.domain = 'test'
      assert @account.valid?
    end
    
    should "not allow 'Test' as a domain" do
      @account.name = 'Test'
      @account.domain = 'Test'
      assert !@account.valid?
    end
    
    should "not allow 2 accounts to have the same domain" do
      @account.name = 'Test 1'
      @account.domain = 'test'
      @account.save!
      
      other_account = Account.new(:name => 'Test 2', :domain => 'test')
      assert !other_account.save
      assert_equal 'has already been taken', other_account.errors[:domain]
    end
  end
end
