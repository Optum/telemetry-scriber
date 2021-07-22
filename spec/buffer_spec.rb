require 'spec_helper'
require 'telemetry/scriber/buffer'

RSpec.describe Telemetry::Scriber::Buffer do
  it { should be_a Module }
  it 'should be able to get the database lock' do
    expect(described_class.database_lock('test_database')).to be_a Concurrent::ReentrantReadWriteLock
  end

  describe 'payloads' do
    it 'can push additional payloads' do
      expect(described_class.payload_push('telegraf', 'this is my line')).to eq true
    end

    it 'can get the payload' do
      expect(described_class.payload('telegraf')).to be_a Concurrent::Array
      expect(described_class.payload('telegraf').count).to be_positive
    end

    it 'can reset the payload' do
      expect(described_class.payload('reset_test').count).to be_zero
      expect(described_class.payload_push('reset_test', 'this is my line')).to eq true
      expect(described_class.payload('reset_test').count).to eq 1
      expect(described_class.payload_reset('reset_test')).to be_a Array
      expect(described_class.payload('reset_test').count).to eq 0
    end
  end

  describe 'db_tag_location' do
    it 'should be able to get the db_tag_location' do
      expect(described_class.db_tag_location('my_consumer', 'database')).to eq 0
      expect(described_class.db_tag_location('my_consumer', 'database')).to eq 0
      expect(described_class.db_tag_location('my_second_consumer', 'telegraf')).to eq 0
    end

    it 'should be able to update the db_tag_location' do
      expect(described_class.db_tag_location_update(11, 'my_consumer', 'database')).to eq 11
      expect(described_class.db_tag_location_update(12, 'my_consumer2', 'database')).to eq 12
      expect(described_class.db_tag_location_update(13, 'my_consumer3', 'database3')).to eq 13

      expect(described_class.db_tag_location('my_consumer', 'database')).to eq 11
      expect(described_class.db_tag_location('my_consumer2', 'database')).to eq 12
      expect(described_class.db_tag_location('my_consumer3', 'database3')).to eq 13
    end
  end

  describe 'db metric counts' do
    it 'should be able to metric_count' do
      expect(described_class.metric_count('telegraf')).to be_a Integer
      expect(described_class.metric_count('not_a_database')).to be_a Integer
    end

    it 'should be able to metric_count_increment' do
      expect(described_class.metric_count_increment('telegraf', 1)).to eq 1
      expect(described_class.metric_count_increment('test_two', 1234)).to eq 1234
    end

    it 'should be able to metric_count_reset' do
      expect(described_class.metric_count_reset('telegraf')).to eq 0
      expect(described_class.metric_count_reset('I_dont_exist')).to eq 0
    end
  end

  describe 'global_metric_counts' do
    it 'should be able to get the global_metric_count' do
      expect(described_class.global_metric_count).to be_a Integer
    end

    it 'should be able to set the global_metric_count' do
      expect(described_class.global_metric_count = 1).to eq 1
      current_value = described_class.global_metric_count
      expect(described_class.global_metric_count_inc(1234)).to eq(current_value + 1234)
    end
  end
end
