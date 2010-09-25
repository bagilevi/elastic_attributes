module ElasticAttributes

  module ClassMethods

    # Define an attribute in the current class.
    #  attribute :image, Image # Image.from(data) will be called on the input['image']
    #  attribute :images, [Array, Image] # array of images - Image.from(data) will be called on all items in input['images'] array
    #  attribute :text, :is_default => true # If the input is not a hash, it will be assigned to this attribute, and all other attributes will be nil
    def attribute(name, type_or_options = nil, options = {})
      if type_or_options.is_a?(Hash)
        options = type_or_options
      else
        options[:type] = type_or_options if type_or_options
      end
      attr_accessor name
      self.attributes ||= {}
      self.attributes[name] = options
      self.default_attribute = name if options[:is_default]
    end

    # Create an object from data
    def from data
      obj = new
      obj.decode data
      obj
    end

  end

  # Unserialize data: map it to the current object attributes.
  def decode data
    if data.is_a? Hash
      self.class.attributes.each do |name, options|
        send("#{name}=", processed_data(data[name] || data[name.to_s], options))
      end
    elsif name = self.class.default_attribute
      options = self.class.attributes[name]
      send("#{name}=", processed_data(data, options))
    else
      raise ArgumentError.new("data is not a Hash (it\'s a #{data.class}) and default attribute not specified")
    end
  end

  # Serialize data
  def encode
    if (name = self.class.default_attribute) && ! (self.class.attributes.keys - [name]).any?{|n|send(n)}
      send(name)
    else
      Hash[(
        self.class.attributes.keys.map do |name|
          value = encoded_data(send(name), self.class.attributes[name])
          [name.to_s, value] if value
        end.compact
      )]
    end
  end

  private

  def processed_data(data, options)
    if data.nil?
      nil
    elsif options[:type]
      types = Array(options[:type])
      main_type = types.first
      if main_type == Array && types.size > 1
        data.map{|data_item| types[1].from data_item }
      elsif main_type.respond_to? :from
        main_type.from data
      elsif main_type == Time
        require 'time'
        Time.parse(data)
      elsif main_type == Hash
        Hash[data]
      else
        main_type.new data
      end
    else
      data
    end
  end

  def encoded_data(data, options)
    if data.nil?
      nil
    elsif options[:type]
      types = Array(options[:type])
      main_type = types.first
      if main_type == Array && types.size > 1
        data.map{|data_item| data_item.encode }
      elsif data.respond_to? :encode
        data.encode
      elsif main_type == Time
        data.to_s
      elsif main_type == Hash
        data
      else
        data
      end
    else
      data
    end
  end

  class << self
    def included(klass)
      klass.instance_eval do
        # cattr_accessible
        [:attributes, :default_attribute].each {|n|instance_eval"def #{n};@#{n};end; def #{n}=(v);@#{n}=v;end" }
      end
      klass.extend ElasticAttributes::ClassMethods
    end
  end

end

