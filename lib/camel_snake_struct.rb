require 'active_support/core_ext/string'

class CamelSnakeStruct
  def self.example(data)
    new_example = new(data)
    walk_example(new_example)
  end

  def self.walk_example(new_example)
    new_example.send(:_method_to_key).keys.each do |m_name|
      result = new_example.public_send(m_name)
      if result.is_a?(CamelSnakeStruct)
        walk_example(result)
      elsif result.is_a?(Array) && result.first.is_a?(CamelSnakeStruct)
        walk_example(result.first)
      end
    end
  end

  def initialize(hash)
    @_raw_hash = hash&.to_h || {}
    @_method_to_key = @_raw_hash.keys.each_with_object({}) do |key, mapping|
      normalize_key = key.gsub('@', '').gsub('.', '_')
      mapping[normalize_key] = key
      mapping[normalize_key.underscore] = key
    end
  end

  def [](key)
    _val(@_raw_hash[key])
  end

  def to_h
    to_hash
  end

  def to_hash
    @_raw_hash
  end

  protected

  attr_reader :_method_to_key

  def _val(val)
    if val.is_a?(Hash)
      CamelSnakeStruct.new(val)
    elsif val.is_a?(Array)
      val.map { |v| _val(v) }
    else
      val
    end
  end

  def method_missing(method_name, *arguments, &block)
    camelize_key = __method_to_key(method_name)
    if camelize_key
      if _define_new_method(method_name, camelize_key)
        send(method_name)
      else # no method defined for empty arrays as we don't know what it returns
        @_raw_hash[camelize_key]
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    camelize_key = __method_to_key(method_name)
    !camelize_key.nil? || super
  end

  def __method_to_key(method_name)
    @_method_to_key[method_name.to_s]
  end

  def _define_hash_method(name, key)
    is_sub_class = self.class != CamelSnakeStruct
    if is_sub_class
      klass = _define_sub_class(name)
      self.class.send(:define_method, name) { @_raw_hash[key] && klass.new(@_raw_hash[key]) }
    else
      define_singleton_method(name) { CamelSnakeStruct.new(@_raw_hash[key]) }
    end
  end

  def _define_array_method(name, key)
    is_sub_class = self.class != CamelSnakeStruct
    if is_sub_class
      klass = _define_sub_class(name.to_s.singularize)
      self.class.send(:define_method, name) { (@_raw_hash[key] || []).map { |v| klass.new(v) } }
    else
      define_singleton_method(name) { @_raw_hash[key].map { |v| CamelSnakeStruct.new(v) } }
    end
  end

  def _define_scaler_array_method(name, key)
    is_sub_class = self.class != CamelSnakeStruct
    if is_sub_class
      self.class.send(:define_method, name) { (@_raw_hash[key] || []) }
    else
      define_singleton_method(name) { @_raw_hash[key] }
    end
  end

  def _define_value_method(name, key)
    is_sub_class = self.class != CamelSnakeStruct
    if is_sub_class
      self.class.send(:define_method, name) { @_raw_hash[key] }
    else
      define_singleton_method(name) { @_raw_hash[key] }
    end
  end

  def _define_new_method(name, key)
    name = name.to_sym
    val = @_raw_hash[key]
    if val.is_a?(Hash)
      _define_hash_method(name, key)
    elsif val.is_a?(Array) && val.first.is_a?(Hash)
      _define_array_method(name, key)
    elsif val.is_a?(Array) && val.empty?
      return false
    elsif val.is_a?(Array)
      _define_scaler_array_method(name, key)
    else
      _define_value_method(name, key)
    end
    true
  end

  def _define_sub_class(name)
    sub_class_name = name.to_s.camelize(:upper)
    self.class.const_get(sub_class_name, false)
  rescue NameError
    self.class.const_set(sub_class_name, Class.new(CamelSnakeStruct))
    self.class.const_get(sub_class_name, false)
  end
end
