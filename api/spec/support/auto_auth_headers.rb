module AutoAuthHeaders
  def self.included(base)
    base.class_eval do
      %i[get post patch put delete].each do |method|
        define_method(method) do |path, **options|
          # Don't inject headers if skip_auth is set
          skip_auth = respond_to?(:example) && example.metadata[:skip_auth]
          unless skip_auth || options[:headers]&.key?("Authorization")
            options[:headers] ||= {}
            options[:headers].merge!(auth_headers) if respond_to?(:auth_headers)
          end

          super(path, **options)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include AutoAuthHeaders, type: :request
end
