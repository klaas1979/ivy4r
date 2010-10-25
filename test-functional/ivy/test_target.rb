$:.unshift File.join(File.dirname(__FILE__),'..','..','lib')

JRuby.objectspace = true if RUBY_PLATFORM == 'java'

require 'test/unit'
require 'rr'
require 'ivy/target'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

module Ivy
  class TargetTest < Test::Unit::TestCase

    def setup
      Ivy::Target.send(:public, :call_nested) # make tested method public
      @ant = Object.new
      @target = Ivy::Target.new(@ant)
    end

    def test_call_nested_simple
      nested = {
        :fileset => {
          :includes => 'bla',
          :excludes => 'blub',
          :dir => 'anything'
        }
      }
      mock(@ant).fileset(nested[:fileset])

      @target.call_nested(nested)
    end

    def test_call_nested_multiply
      nested = {
        :fileset => {
          :includes => 'bla',
          :excludes => 'blub',
          :dir => 'anything'
        },
        :other => {
          :param => 'myparam'
        }
      }
      mock(@ant).fileset nested[:fileset]
      mock(@ant).other nested[:other]

      @target.call_nested(nested)
    end

    def test_call_nested_list_with_same_method
      nested = {
        :fileset => [
          {
            :includes => 'bla',
            :excludes => 'blub',
            :dir => 'anything'
          },
          {
            :includes => 'otherbla',
            :excludes => 'otherblub',
            :dir => 'otheranything'
          }
        ]
      }
      mock(@ant).fileset nested[:fileset][0]
      mock(@ant).fileset nested[:fileset][1]

      @target.call_nested(nested)
    end

    def test_call_recursive_nested
      nested = {
        :taskdef =>
          {
          :name => 'bla',
          :nested => {
            :fileset => {
              :includes => 'bla',
              :excludes => 'blub',
              :dir => 'anything'}
          }
        }
      }

      # define the method that yields if a block is given, to test the nested stuff
      def @ant.taskdef(p)
        raise "Invalid params to many" unless p.size == 1
        raise "Wrong parameter value" unless 'bla' == p[:name]
        raise "missing block for method" unless block_given?
        yield
      end
      mock(@ant).fileset nested[:taskdef][:nested][:fileset]

      @target.call_nested(nested)
    end
  end
end
