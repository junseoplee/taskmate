# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsSummary, type: :model do
  describe 'validations' do
    subject { build(:analytics_summary) }

    it { should validate_presence_of(:metric_name) }
    it { should validate_presence_of(:metric_type) }
    it { should validate_presence_of(:time_period) }
    it { should validate_numericality_of(:metric_value).is_greater_than_or_equal_to(0) }
    
    it { should validate_inclusion_of(:metric_type).in_array(['count', 'average', 'sum', 'percentage']) }
    it { should validate_inclusion_of(:time_period).in_array(['hourly', 'daily', 'weekly', 'monthly']) }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
  end

  describe 'callbacks' do
    it 'sets calculated_at before validation if not present' do
      summary = build(:analytics_summary, calculated_at: nil)
      expect { summary.valid? }.to change { summary.calculated_at }.from(nil)
    end
  end

  describe 'scopes' do
    before { AnalyticsSummary.delete_all }
    
    let!(:task_summaries) { create_list(:analytics_summary, 3, metric_name: 'tasks_completed', time_period: 'hourly') }
    let!(:user_summaries) { create_list(:analytics_summary, 2, metric_name: 'users_active', time_period: 'hourly') }
    let!(:daily_summaries) { create_list(:analytics_summary, 2, time_period: 'daily', metric_name: 'unique_daily_metric') }
    let!(:weekly_summaries) { create_list(:analytics_summary, 1, time_period: 'weekly', metric_name: 'unique_weekly_metric') }

    describe '.by_metric' do
      it 'filters summaries by metric name' do
        expect(AnalyticsSummary.by_metric('tasks_completed')).to match_array(task_summaries)
        expect(AnalyticsSummary.by_metric('users_active')).to match_array(user_summaries)
      end
    end

    describe '.by_period' do
      it 'filters summaries by time period' do
        expect(AnalyticsSummary.by_period('daily')).to match_array(daily_summaries)
        expect(AnalyticsSummary.by_period('weekly')).to match_array(weekly_summaries)
      end
    end

    describe '.recent' do
      it 'returns summaries from last 30 days by default' do
        old_summary = create(:analytics_summary, calculated_at: 31.days.ago)
        recent_summaries = AnalyticsSummary.recent
        
        expect(recent_summaries).not_to include(old_summary)
        expect(recent_summaries.count).to eq(8) # task + user + daily + weekly summaries
      end
    end
  end

  describe '#formatted_value' do
    it 'formats percentage values with % symbol' do
      summary = create(:analytics_summary, metric_type: 'percentage', metric_value: 85.5)
      expect(summary.formatted_value).to eq('85.5%')
    end

    it 'formats count values as integers' do
      summary = create(:analytics_summary, metric_type: 'count', metric_value: 42.0)
      expect(summary.formatted_value).to eq('42')
    end

    it 'formats average values with 2 decimal places' do
      summary = create(:analytics_summary, metric_type: 'average', metric_value: 3.14159)
      expect(summary.formatted_value).to eq('3.14')
    end

    it 'formats sum values as integers' do
      summary = create(:analytics_summary, metric_type: 'sum', metric_value: 1000.0)
      expect(summary.formatted_value).to eq('1000')
    end
  end

  describe '#to_chart_data' do
    it 'returns summary in chart-compatible format' do
      summary = create(:analytics_summary,
        metric_name: 'tasks_completed',
        metric_value: 25.0,
        time_period: 'daily',
        calculated_at: Date.current.beginning_of_day
      )
      
      chart_data = summary.to_chart_data
      
      expect(chart_data).to include(
        name: 'tasks_completed',
        value: 25.0,
        period: 'daily',
        date: Date.current.beginning_of_day.to_date
      )
    end
  end
end