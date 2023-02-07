# frozen_string_literal: true

require 'rspec/snapshot/matchers/match_snapshot'
require 'rspec/snapshot/matchers/match_inline_snapshot'

module RSpec
  module Snapshot
    # rubocop:disable Style/Documentation
    module Matchers
      def match_snapshot(snapshot_name, config = {})
        directory = RSpec.configuration.snapshot_dir
        metadata = RSpec.current_example.metadata

        writer = FileSnapshotWriter.new(
          snapshot_name,
          directory,
          metadata
        )

        reader = FileSnapshotReader.new(
          snapshot_name,
          directory
        )

        SnapshotMatcher.new(config, reader, writer)
      end

      alias snapshot match_snapshot

      def match_inline_snapshot(expected = nil, config = {})
        metadata = RSpec.current_example.metadata

        reader = InlineSnapshotReader.new(expected)
        writer = YAInlineSnapshotWriter.new(metadata[:file_path], caller)

        SnapshotMatcher.new(config, reader, writer)
      end
    end
    # rubocop:enable Style/Documentation
  end
end

RSpec.configure do |config|
  config.include RSpec::Snapshot::Matchers
end
