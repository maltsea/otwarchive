module ParameterSanitization
  extend ActiveSupport::Concern

  included do
    before_action :sanitize_ac_params
  end

  def sanitize_ac_params
    sanitize_params(params.to_unsafe_h).each do |key, value|
      params[key] = transform_sanitized_hash_to_ac_params(key, value)
    end
  end

  def transform_sanitized_hash_to_ac_params(key, value)
    if value.is_a?(Hash)
      ActionController::Parameters.new(value)
    elsif value.is_a?(Array)
      value.map.with_index do |val, _index|
        transform_sanitized_hash_to_ac_params(key, val)
      end
    else
      value
    end
  end
end
