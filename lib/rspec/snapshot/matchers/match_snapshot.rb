# frozen_string_literal: true

require 'fileutils'
require 'rspec/snapshot/default_serializer'
require_relative './matcher'

class FileSnapshotWriter
  def initialize(name, directory, metadata)
    @name = name
    @directory = directory
    @metadata = metadata
  end

  private def snapshot_path
    @snapshot_path ||= File.join(@directory, "#{@name}.snap")
  end

  private def create_snapshot_dir
    return if Dir.exist?(File.dirname(snapshot_path))

    FileUtils.mkdir_p(File.dirname(snapshot_path))
  end

  private def snapshot_dir
    if @directory.to_s == 'relative'
      File.dirname(@metadata[:file_path]) << '/__snapshots__'
    else
      @directory
    end
  end

  def write(snapshot, force)
    return unless should_write? || force

    create_snapshot_dir

    RSpec.configuration.reporter.message(
      "Snapshot written: #{snapshot_path}"
    )
    file = File.new(snapshot_path, 'w+')
    file.write(snapshot)
    file.close
  end

  private def should_write?
    !File.exist?(@snapshot_path)
  end
end

class FileSnapshotReader
  def initialize(name, directory)
    @name = name
    @directory = directory
  end

  def read
    file = File.new(snapshot_path)
    value = file.read
    file.close
    value
  end

  private def snapshot_path
    @snapshot_path ||= File.join(@directory, "#{@name}.snap")
  end
end

module RSpec
  module Snapshot
    module Matchers
      # RSpec matcher for snapshot testing
      class MatchSnapshot < Matcher
        def initialize(metadata, snapshot_name, config)
          super(metadata, config)

          @snapshot_name = snapshot_name
          @snapshot_path = File.join(snapshot_dir, "#{@snapshot_name}.snap")
          create_snapshot_dir
        end

        def matches?(actual)
          @actual = serialize(actual)

          write_snapshot

          @expected = read_snapshot

          @actual == @expected
        end

        # === is the method called when matching an argument
        alias === matches?
        alias match matches?

        private def snapshot_dir
          if RSpec.configuration.snapshot_dir.to_s == 'relative'
            File.dirname(@metadata[:file_path]) << '/__snapshots__'
          else
            RSpec.configuration.snapshot_dir
          end
        end

        private def create_snapshot_dir
          return if Dir.exist?(File.dirname(@snapshot_path))

          FileUtils.mkdir_p(File.dirname(@snapshot_path))
        end

        private def write_snapshot
          return unless should_write?

          RSpec.configuration.reporter.message(
            "Snapshot written: #{@snapshot_path}"
          )
          file = File.new(@snapshot_path, 'w+')
          file.write(@actual)
          file.close
        end

        private def should_write?
          update_snapshots? || !File.exist?(@snapshot_path)
        end

        private def read_snapshot
          file = File.new(@snapshot_path)
          value = file.read
          file.close
          value
        end
      end
    end
  end
end
