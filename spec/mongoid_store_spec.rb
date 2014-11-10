require 'helper'

describe ActiveSupport::Cache::MongoidStore do
  let(:collection)  { Mongoid.session(:default)[:rails_cache] }
  let(:store)       { ActiveSupport::Cache::MongoidStore.new }

  describe "#write" do
    before(:each) do
      store.write('foo', 'bar')
    end
    let(:document) { collection.find(_id: 'foo').first }

    it "sets _id to key" do
      document['_id'].should == 'foo'
    end

    it "sets value key to value" do
      store.read('foo').should == 'bar'
    end

    it "sets expires in to default if not provided" do
      document['expires_at'].to_i.should == (Time.now.utc + 1.hour).to_i
    end

    it "sets expires_at if expires_in provided" do
      store.write('foo', 'bar', expires_in: 5.seconds)
      document['expires_at'].to_i.should == (Time.now.utc + 5.seconds).to_i
    end

    it "always sets key as string" do
      store.write(:baz, 'wick')
      doc = collection.find(_id: 'baz').first
      doc.should_not be_nil
      doc['_id'].should be_instance_of(String)
    end
  end

  describe "#read" do
    before(:each) do
      store.write('foo', 'bar')
    end
    let(:document) { collection.find(_id: 'foo').first }

    it "returns nil for key not found" do
      store.read('non:existent:key').should be_nil
    end

    it "returns nil for existing but expired key" do
      collection.find(_id: 'foo').upsert(_id: 'foo', value: 'bar', expires_at: 5.seconds.ago)
      store.read('foo').should be_nil
    end

    it "return value for existing and not expired key" do
      store.write('foo', 'bar', :expires_in => 20.seconds)
      store.read('foo').should == 'bar'
    end

    it "works with symbol" do
      store.read(:foo).should == 'bar'
    end
  end

  describe "#delete" do
    before(:each) do
      store.write('foo', 'bar')
    end

    it "delete key from cache" do
      store.read('foo').should_not be_nil
      store.delete('foo')
      store.read('foo').should be_nil
    end

    it "works with symbol" do
      store.read(:foo).should_not be_nil
      store.delete(:foo)
      store.read(:foo).should be_nil
    end
  end

  describe "#delete_matched" do
    before(:each) do
      store.write('foo1', 'bar')
      store.write('foo2', 'bar')
      store.write('baz', 'wick')
    end

    it "deletes matching keys" do
      store.read('foo1').should_not be_nil
      store.read('foo2').should_not be_nil
      store.delete_matched(/foo/)
      store.read('foo1').should be_nil
      store.read('foo2').should be_nil
    end

    it "does not delete unmatching keys" do
      store.delete_matched('foo')
      store.read('baz').should_not be_nil
    end
  end

  describe "#exist?" do
    before(:each) do
      store.write('foo', 'bar')
    end

    it "returns true if key found" do
      store.exist?('foo').should == true
    end

    it "returns false if key not found" do
      store.exist?('not:found:key').should == false
    end

    it "works with symbol" do
      store.exist?(:foo).should == true
      store.exist?(:notfoundkey).should == false
    end
  end

  describe "#clear" do
    before(:each) do
      store.write('foo', 'bar')
      store.write('baz', 'wick')
    end

    it "clear all keys" do
      collection.find.count.should == 2
      store.clear
      collection.find.count.should == 0
    end
  end
end
