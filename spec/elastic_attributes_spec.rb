require 'rspec'
require File.dirname(__FILE__) + '/../lib/elastic_attributes'

class Person
  include ElasticAttributes
  attribute :name
end

class City
  include ElasticAttributes
  attribute :name
  attribute :mayor, Person
end

class Country
  include ElasticAttributes
  attribute :name
  attribute :cities, [Array, City] # Array of Cities
end

class Item
  include ElasticAttributes
  attribute :description, :is_default => true
  attribute :notes
end

class List
  include ElasticAttributes
  attribute :items, [Array, Item]
end

class Apple
  include ElasticAttributes
  attribute :picked_at, Time
end

class Collection
  include ElasticAttributes
  attribute :things, Array
end

class House
  include ElasticAttributes
  attribute :tenants, Hash
end


describe ElasticAttributes do

  describe "decoding" do

    it "should handle simple attribute" do
      person = Person.from({'name' => 'Andrea'})
      person.name.should == 'Andrea'
    end

    it "should create an object with the given type" do
      city = City.from({'name' => 'Budapest', 'mayor' => {'name' => 'Gábor Demszky'}})
      city.name.should == 'Budapest'
      city.mayor.should be_a Person
      city.mayor.name.should == 'Gábor Demszky'
    end

    it "should create an object with missing custom-typed attribute" do
      city = City.from({'name' => 'Budapest'})
      city.name.should == 'Budapest'
      city.mayor.should be_nil
    end

    it "should create an array of objects with a given type" do
      country = Country.from({'name' => 'Hungary', 'cities' => [{'name' => 'Budapest'}, {'name' => 'Miskolc'}]})
      country.cities.each{|city| city.should be_a City}
      country.cities.first.name.should == 'Budapest'
    end

    it "should use default attribute if the source data is not a hash" do
      list = List.from({'items' => ['buy milk',
                                    'feed cat',
                                    {'description' => 'water plants', 'notes' => 'in the room too'}
                                   ]})
      list.items.each{|item| item.should be_a Item}
      list.items.first.description.should == 'buy milk'
      list.items.first.notes.should be_nil
      list.items.last.description.should == 'water plants'
      list.items.last.notes.should == 'in the room too'
    end

    it "should handle Time" do
      apple = Apple.from({'picked_at' => '2010-09-25 15:15'})
      apple.picked_at.should == Time.parse('2010-09-25 15:15')
    end

    it "should handle Array" do
      a = ['foo', :bar, {:name => 'John'}]
      collection = Collection.from({'things' => a})
      collection.things.should == a
    end

    it "should handle Hash" do
      h = {:basement => 'John', :floor1 => 'Mary'}
      house = House.from({'tenants' => h})
      house.tenants.should == h
    end
  end

  describe "encoding" do
    it "should be the reverse of decoding" do
      [
              [Person, {'name' => 'Andrea'}],
              [City, {'name' => 'Budapest', 'mayor' => {'name' => 'Gábor Demszky'}}],
              [City, {'name' => 'Budapest'}],
              [Country, {'name' => 'Hungary', 'cities' => [{'name' => 'Budapest'}, {'name' => 'Miskolc'}]}],
              [List, {'items' => ['buy milk',
                                    'feed cat',
                                    {'description' => 'water plants', 'notes' => 'in the room too'}
                                   ]}],
              [Collection, {'things' => ['foo', :bar, {:name => 'John'}]}],
              [House, {'tenants' => {:basement => 'John', :floor1 => 'Mary'}}]
      ].each do |klass, input|
        klass.from(input).encode.should == input
      end
    end

    it "should encode time" do
      apple = Apple.from({'picked_at' => '2010-09-25 15:15'})
      apple.encode['picked_at'].should be_a String
      Time.parse(apple.encode['picked_at']).should == Time.parse('2010-09-25 15:15')
    end
  end
end
