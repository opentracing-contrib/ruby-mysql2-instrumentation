require 'spec_helper'

RSpec.describe Mysql2::Instrumentation do
  describe "Class Methods" do
    it { should respond_to :instrument }
  end

  let (:tracer) { OpenTracingTestTracer.build }

  before do
    Mysql2::Instrumentation.instrument(tracer: tracer)

    # prevent actual client connections
    allow_any_instance_of(Mysql2::Client).to receive(:connect) do |*args|
      @connect_args = []
      @connect_args << args
    end

    # mock query_original, since we don't care about the results
    allow_any_instance_of(Mysql2::Client).to receive(:query_original).and_return(Mysql2::Result.new)
  end

  let (:host) { 'localhost '}
  let (:database) { 'test_sql2 '}
  let (:username) { 'root '}
  let (:client) { Mysql2::Client.new(:host => host, :database => database, :username => username) }

  describe :instrument do
    it "patches the class's query method" do
      expect(client).to respond_to(:query)
      expect(client).to respond_to(:query_original)
    end
  end

  describe 'successful query' do
    it 'calls query_original when calling query' do
      expect(client).to receive(:query_original)

      client.query("SELECT * FROM test_mysql2")
    end

    it 'adds a span for a query with tags' do
      statement = "SELECT * FROM test_mysql2" * 4096
      client.query(statement)

      expect(tracer.spans.count).to eq 1
      expect(tracer.spans.last.operation_name).to eq 'SELECT'

      expected_tags = {
        'component' => 'mysql2',
        'db.type' => 'mysql',
        'span.kind' => 'client',
        'db.instance' => database,
        'db.statement' => statement[0..1023],
        'db.user' => username,
      }
      expect(tracer.spans.last.tags).to eq expected_tags
    end
  end

  describe 'failed query' do
    before do
      allow(client).to receive(:query_original).and_raise('error')
    end

    it 'sets the error tag and log' do
      statement = 1234
      begin
        client.query(statement)
      rescue => e
      end

      expected_tags = {
        'component' => 'mysql2',
        'db.type' => 'mysql',
        'span.kind' => 'client',
        'db.instance' => database,
        'db.statement' => statement.to_s,
        'db.user' => username,
        'error' => true,
      }
      expect(tracer.spans.last.tags).to eq expected_tags
      expect(tracer.spans.last.operation_name).to eq 'sql.query'

      expect(tracer.spans.last.logs.last[:key]).to eq('message')
      expect(tracer.spans.last.logs.last[:value]).to eq('error')
    end
  end
end
