require 'mysql2/instrumentation/version'
require 'opentracing'

module Mysql2
  module Instrumentation

    class << self

      attr_accessor :tracer

      def instrument(tracer: OpenTracing.global_tracer)
        begin
          require 'mysql2'
        rescue LoadError
          return
        end

        @tracer = tracer

        patch_query unless @instrumented

        @instrumented = true
      end

      def patch_query
        ::Mysql2::Client.class_eval do

          alias_method :query_original, :query

          def query(sql, options = {})
            tags = {
              'component' => 'mysql2',
              'db.instance' => @query_options.fetch(:database, ''),
              'db.statement' => sql,
              'db.user' => @query_options.fetch(:username, ''),
              'db.type' => 'mysql',
              'span.kind' => 'client',
            }

            span = ::Mysql2::Instrumentation.tracer.start_span(sql, tags: tags)
            query_original(sql, options)
          rescue => error
            span.set_tag("error", true)
            span.log_kv(key: "message", value: error.message)

            raise error
          ensure
            span.finish if span
          end
        end # class_eval
      end
    end
  end
end
