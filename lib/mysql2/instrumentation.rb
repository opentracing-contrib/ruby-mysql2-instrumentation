require 'mysql2/instrumentation/version'
require 'opentracing'

module Mysql2
  module Instrumentation

    class << self

      def instrument(tracer: OpenTracing.global_tracer)
        return if @instrumented

        begin
          require 'mysql2'
        rescue LoadError
          return
        end

        @tracer = tracer

        patch_query

        @instrumented = true
      end

      def patch_query
        ::Mysql2::Client.class_eval do

          alias_method :query_original, :query

          def query(sql, options = {})
            tags = {
              'component' => 'mysql2',
              'db.instance' => '',
              'db.statement' => sql,
              'db.type' => 'mysql',
              'span.kind' => 'client',
            }

            span = OpenTracing.start_span("mysql2.query", tags: tags)
            query_original(sql, options)
          ensure
            span.finish if span
          end
        end # class_eval
      end
    end
  end
end
