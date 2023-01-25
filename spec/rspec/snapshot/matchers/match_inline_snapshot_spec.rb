# frozen_string_literal: true

require 'spec_helper'

describe RSpec::Snapshot::Matchers::MatchInlineSnapshot do
  def build_matcher
    described_class.new(
      metadata: metadata,
      expected: expected,
      config: config,
      call_stack: call_stack
    )
  end

  let(:metadata) { { file_path: 'spec/example_spec.rb' } }
  let(:config) { {} }
  let(:expected) { 'foobar' }
  let(:call_stack) { [] }

  it_behaves_like 'a snapshot matcher'

  describe '.matches?' do
    let(:serializer) { instance_double(RSpec::Snapshot::DefaultSerializer) }

    before do
      allow(RSpec::Snapshot::DefaultSerializer).to(
        receive(:new).and_return(serializer)
      )
      allow(serializer).to receive(:dump)

      class_double(InlineSnapshotWriter).as_stubbed_const
    end

    context 'when UPDATE_SNAPSHOTS is enabled' do
      before do
        allow(ENV).to receive(:[]).with('UPDATE_SNAPSHOTS').and_return('true')
      end

      it 'writes a snapshot value' do
        expect(InlineSnapshotWriter).to have_received(:write)
      end
    end

    context 'when the snapshot is missing' do
      let(:expected) { nil }

      it 'writes a snapshot value' do
        expect(InlineSnapshotWriter).to have_received(:write)
      end
    end

    context 'when the snapshot is present and UPDATE_SNAPSHOT is disabled' do
      context 'when the snapshot matches' do

      end

      context 'when the snapshot does not match' do

      end
    end
  end
end
