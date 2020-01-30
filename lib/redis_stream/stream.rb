module RedisStream
  class Stream
    attr_reader :key

    def initialize(key:, redis:)
      @key = key
      @redis = redis
    end

    def add(entry)
      @redis.xadd(key, value: entry)
    end

    def len
      @redis.xlen(key)
    end

    def clear
      @redis.xtrim(key, 0)
    end

    def each_message
      last_id = '0'

      while
        result = @redis.xread(key, last_id, count: 1)
        break if result.empty?

        messages = result[key]
        messages.each do |message|
          last_id, entry = message
          yield(entry['value'])
        end
      end
    end

    # XREVRANGE [name] + - COUNT 1
    def last
      _id, entry = @redis.xrevrange(key, '+', '-', count: 1).first
      return if entry.nil?

      entry['value']
    end

    # XRANGE [name] - + COUNT 1
    def first
      _id, entry = @redis.xrange(key, '-', '+', count: 1).first
      return if entry.nil?

      entry['value']
    end
  end
end
