# frozen_string_literal: true

module SchemaHelpers
  def read_schema(filename, schema_version = 'v1')
    JSON.parse(
      File.read(
        Rails.root.join(
          'modules',
          'appeals_api',
          'config',
          'schemas',
          schema_version,
          filename
        )
      )
    )
  end

  def resolver
    proc do |uri|
      json_file = uri.path
      parsed_schema = JSON.parse File.read shared_dir(json_file)
      parsed_schema['properties'].values.first
    end
  end

  def override_max_lengths(appeal, schema)
    JSONSchemer.schema(schema,
                       after_property_validation: proc do |data, property, property_schema, _parent|
                         data[property] = 'W' * property_schema['maxLength'] if property_schema['maxLength']
                       end).valid?(appeal.form_data)
    appeal.form_data
  end

  private

  def shared_dir(file)
    Rails.root.join('modules', 'appeals_api', Settings.modules_appeals_api.schema_dir, 'shared', 'v1', file)
  end
end
