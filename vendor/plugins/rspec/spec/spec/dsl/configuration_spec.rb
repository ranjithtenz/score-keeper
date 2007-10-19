require File.dirname(__FILE__) + '/../../spec_helper.rb'

module Spec
  module DSL
    ConfigurationSpec = describe Configuration, :shared => true do
      before(:each) do
        @config = Configuration.new
        @behaviour = mock("behaviour")
      end      
    end
    
    describe Configuration, "#mock_with" do
      include ConfigurationSpec
      it "should default mock framework to rspec" do
        @config.mock_framework.should =~ /\/plugins\/mock_frameworks\/rspec$/
      end

      it "should let you set rspec mocking explicitly" do
        @config.mock_with(:rspec)
        @config.mock_framework.should =~ /\/plugins\/mock_frameworks\/rspec$/
      end

      it "should let you set mocha" do
        @config.mock_with(:mocha)
        @config.mock_framework.should =~ /\/plugins\/mock_frameworks\/mocha$/
      end

      it "should let you set flexmock" do
        @config.mock_with(:flexmock)
        @config.mock_framework.should =~ /\/plugins\/mock_frameworks\/flexmock$/
      end

      it "should let you set rr" do
        @config.mock_with(:rr)
        @config.mock_framework.should =~ /\/plugins\/mock_frameworks\/rr$/
      end

      it "should let you set an arbitrary adapter module" do
        adapter = Module.new
        @config.mock_with(adapter)
        @config.mock_framework.should == adapter
      end
    end

    describe Configuration, "#include" do
      include ConfigurationSpec
      it "should let you define modules to be included" do
        mod = Module.new
        @config.include mod
        @config.modules_for(nil).should include(mod)
      end

      it "should let you define modules to be included for a behaviour_type" do
        mod = Module.new
        @config.include mod, :behaviour_type => :foobar
        @config.modules_for(:foobar).should include(mod)
      end

      [:prepend_before, :append_before, :prepend_after, :append_after].each do |m|
        it "should delegate ##{m} to Example class" do
          Example.should_receive(m).with(:whatever)
          @config.__send__(m, :whatever)
        end
      end
    end
  end
end
