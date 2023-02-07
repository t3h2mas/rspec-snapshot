# frozen_string_literal: true

require 'fileutils'
require 'rspec/snapshot/default_serializer'

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for snapshot testing
      class SnapshotMatcher
        attr_reader :actual, :expected

        def initialize(config, snapshot_reader, snapshot_writer)
          @config = config
          @serializer = serializer_class.new

          @snapshot_reader = snapshot_reader
          @snapshot_writer = snapshot_writer
        end

        def matches?(actual)
          @actual = serialize(actual)

          @snapshot_writer.write(@actual, update_snapshots?)

          @expected = @snapshot_reader.read

          @actual == @expected
        end

        private def serializer_class
          if @config[:snapshot_serializer]
            @config[:snapshot_serializer]
          elsif RSpec.configuration.snapshot_serializer
            RSpec.configuration.snapshot_serializer
          else
            DefaultSerializer
          end
        end

        private def serialize(value)
          return value if value.is_a?(String)

          @serializer.dump(value)
        end

        private def update_snapshots?
          ENV['UPDATE_SNAPSHOTS'] # rubocop:todo Style/FetchEnvVar
        end

        def description
          "to match a snapshot containing: \"#{@expected}\""
        end

        def diffable?
          true
        end

        def failure_message
          "\nexpected: #{@expected}\n     got: #{@actual}\n"
        end

        def failure_message_when_negated
          "\nexpected: #{@expected} not to match #{@actual}\n"
        end
      end
    end
  end
end
