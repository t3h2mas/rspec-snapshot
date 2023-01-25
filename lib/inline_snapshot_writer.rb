# frozen_string_literal: true

require_relative './ast/file_rewriter'
require_relative './ast/snapshot_upserter'

class InlineSnapshotWriter

  def self.write(test_file_path, matcher_line_index, actual)
    new(test_file_path, matcher_line_index, actual).write
  end

  def initialize(test_file_path, matcher_line_index, actual)
    @test_file_path = test_file_path
    @matcher_line_index = matcher_line_index
    @actual = actual

    @matcher_name = 'match_inline_snapshot'
    @rewriter = AST::FileRewriter.new(AST::SnapshotUpserter)
  end

  def write
    lines = File.read(@test_file_path).split("\n")

    start_index = matcher_start_index(lines)

    indentation_level = indentation_spaces(lines[@matcher_line_index])

    updated_source = update_matcher_source(indentation_level)

    File.write(@test_file_path,
                @rewriter.rewrite(@test_file_path, start_index, updated_source))
  end

  private def matcher_start_index(lines)
    previous_lines = lines[..@matcher_line_index - 1]
    matcher_line_start = previous_lines.sum { |l| l.length + 1 }
    matcher_start = lines[@matcher_line_index].index(@matcher_name)

    matcher_line_start + matcher_start
  end

  private def indentation_spaces(line)
    line.length - line.lstrip.length
  end

  private def actual_with_indent(indentation_level)
    @actual.split("\n").map do |line|
      indent(line, indentation_level)
    end.join("\n")
  end

  private def update_matcher_source(indentation_level)
    [
      'match_inline_snapshot(',
      indent('<<~SNAPSHOT', indentation_level + 2),
      actual_with_indent(indentation_level + 4),
      indent('SNAPSHOT', indentation_level + 2),
      indent(')', indentation_level)
    ].join("\n")
  end

  private def indent(text, level)
    text.rjust(level + text.length, ' ')
  end
end
