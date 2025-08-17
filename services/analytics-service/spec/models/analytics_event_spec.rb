# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsEvent, type: :model do
  describe 'validations' do
    subject { build(:analytics_event) }

    it { should validate_presence_of(:event_name) }
    it { should validate_presence_of(:event_type) }
    it { should validate_presence_of(:source_service) }

    it { should validate_inclusion_of(:event_type).in_array([ 'task', 'user', 'system' ]) }
    it { should validate_inclusion_of(:source_service).in_array([ 'user-service', 'task-service', 'analytics-service', 'file-service' ]) }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'callbacks' do
    it 'sets occurred_at before validation if not present' do
      event = build(:analytics_event, occurred_at: nil)
      expect { event.valid? }.to change { event.occurred_at }.from(nil)
    end

    it 'does not override existing occurred_at' do
      time = 1.hour.ago
      event = build(:analytics_event, occurred_at: time)
      event.valid?
      expect(event.occurred_at).to eq(time)
    end
  end

  describe 'scopes' do
    before { AnalyticsEvent.delete_all }

    let!(:task_events) { create_list(:analytics_event, 3, event_type: 'task', event_name: 'unique_task_event', occurred_at: 3.days.ago) }
    let!(:user_events) { create_list(:analytics_event, 2, event_type: 'user', event_name: 'unique_user_event', occurred_at: 3.days.ago) }
    let!(:today_events) { create_list(:analytics_event, 2, event_type: 'system', event_name: 'unique_today_event', occurred_at: Time.current) }
    let!(:yesterday_events) { create_list(:analytics_event, 1, event_type: 'system', event_name: 'unique_yesterday_event', occurred_at: 1.day.ago) }

    describe '.by_type' do
      it 'filters events by type' do
        expect(AnalyticsEvent.by_type('task')).to match_array(task_events)
        expect(AnalyticsEvent.by_type('user')).to match_array(user_events)
      end
    end

    describe '.by_date_range' do
      it 'filters events by date range' do
        start_date = Date.current.beginning_of_day
        end_date = Date.current.end_of_day

        result = AnalyticsEvent.by_date_range(start_date, end_date)
        expect(result).to match_array(today_events)
      end
    end

    describe '.recent' do
      it 'returns events from last 7 days by default' do
        old_event = create(:analytics_event, occurred_at: 8.days.ago)
        recent_events = AnalyticsEvent.recent

        expect(recent_events).not_to include(old_event)
        expect(recent_events.count).to eq(8) # today + yesterday + task + user events (all within 7 days)
      end
    end
  end

  describe '#metadata' do
    it 'can store and retrieve JSON metadata' do
      metadata = { 'task_id' => 123, 'priority' => 'high' }
      event = create(:analytics_event, metadata: metadata)

      expect(event.reload.metadata).to eq(metadata)
    end
  end

  describe '#to_metrics' do
    it 'returns event in metrics format' do
      event = create(:analytics_event,
        event_name: 'task.created',
        event_type: 'task',
        source_service: 'task-service',
        metadata: { 'priority' => 'high' }
      )

      metrics = event.to_metrics

      expect(metrics).to include(
        name: 'task.created',
        type: 'task',
        service: 'task-service',
        timestamp: event.occurred_at.to_i
      )
      expect(metrics[:metadata]).to eq(event.metadata)
    end
  end
end
