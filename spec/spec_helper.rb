gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/matchers'

class RangeMatcher
  def initialize(operator, limit)
    @operator = operator.to_sym
    @limit = limit
  end

  def description
    "be #{operator} #{@limit}"
  end

  def matches?(subject)
    subject.send(@operator, @limit)
  end

  def failure_message_for_should
    "expected #{operator} #{@limit}"
  end

  def failure_message_for_should_not
    "expected not #{operator} #{@limit}"
  end
end

def be_lt(value)
  RangeMatcher.new('<', value)
end

def be_lte(value)
  RangeMatcher.new('<=', value)
end
