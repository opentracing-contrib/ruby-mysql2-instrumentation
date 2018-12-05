
class MockClient < Mysql2::Client

  attr_reader :database, :username

  def initialize(opts = {})
    @database = opts[:database]
    @username = opts[:username]
  end

  def query(sql, options = {})
    _query(sql, options)
  end

  def _query(sql, options = {})
    return sql
  end
end
