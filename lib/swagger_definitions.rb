# lib/swagger_definitions.rb
require 'swagger/blocks'

module SwaggerDefinitions
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'API Documentation'
      key :description, 'Comprehensive API documentation for the Ruby gem'
      contact do
        key :name, 'API Support'
      end
      license do
        key :name, 'MIT'
        key :url, 'https://opensource.org/licenses/MIT'
      end
    end
    key :host, 'api.example.com'
    key :basePath, '/v1'
    key :schemes, ['https']
    key :consumes, ['application/json']
    key :produces, ['application/json']

    security_definition :api_key do
      key :type, :apiKey
      key :name, 'Authorization'
      key :in, :header
    end

    security do
      key :api_key, []
    end
  end

  swagger_path '/resources' do
    operation :get do
      key :summary, 'Retrieve resources'
      key :description, 'Returns a paginated list of all available resources'
      key :operationId, 'getResources'
      key :tags, ['Resources']

      parameter do
        key :name, :limit
        key :in, :query
        key :description, 'Maximum number of results'
        key :required, false
        key :type, :integer
      end

      response 200 do
        key :description, 'Successful response'
        schema do
          key :type, :array
          items do
            key :$ref, :Resource
          end
        end
      end

      response 400 do
        key :description, 'Invalid request parameters'
        schema do
          key :$ref, :Error
        end
      end

      response 401 do
        key :description, 'Unauthorized'
        schema do
          key :$ref, :Error
        end
      end

      response 404 do
        key :description, 'Resources not found'
        schema do
          key :$ref, :Error
        end
      end
    end
  end

  swagger_schema :Resource do
    key :required, %i[id name]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :name do
      key :type, :string
    end
  end

  swagger_schema :Error do
    key :required, %i[code message]
    property :code do
      key :type, :integer
    end
    property :message do
      key :type, :string
    end
  end
end
