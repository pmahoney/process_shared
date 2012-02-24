require 'rubygems' if RUBY_VERSION =~ /^1.8/
gem 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/matchers'

require 'process_shared'
require 'process_shared/lock_behavior'

class RangeMatcher
  def initialize(operator, limit)
    @operator = operator.to_sym
    @limit = limit
  end

  def description
    "be #{operator} #{@limit}"
  end

  def matches?(subject)
    @subject = subject
    subject.send(@operator, @limit)
  end

  def failure_message_for_should
    "expected #{@operator} #{@limit}, not #{@subject}"
  end

  def failure_message_for_should_not
    "expected not #{@operator} #{@limit}, not #{@subject}"
  end
end

def be_lt(value)
  RangeMatcher.new('<', value)
end

def be_gt(value)
  RangeMatcher.new('>', value)
end

def be_lte(value)
  RangeMatcher.new('<=', value)
end

def be_gte(value)
  RangeMatcher.new('>=', value)
end
