# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsSummariesController, type: :controller do
  describe 'GET #index' do
    let!(:daily_summaries) { create_list(:analytics_summary, 3, time_period: 'daily') }
    let!(:weekly_summaries) { create_list(:analytics_summary, 2, time_period: 'weekly') }

    context 'without filters' do
      it 'returns all summaries' do
        get :index

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(5)
      end
    end

    context 'with metric_name filter' do
      it 'returns filtered summaries' do
        get :index, params: { metric_name: 'tasks_completed' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.all? { |summary| summary['metric_name'] == 'tasks_completed' }).to be true
      end
    end

    context 'with time_period filter' do
      it 'returns filtered summaries' do
        get :index, params: { time_period: 'daily' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
        expect(json_response.all? { |summary| summary['time_period'] == 'daily' }).to be true
      end
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        analytics_summary: {
          metric_name: 'tasks_completed',
          metric_type: 'count',
          metric_value: 42.5,
          time_period: 'daily',
          metadata: { period_start: Date.current.beginning_of_day },
          user_id: 1
        }
      }
    end

    let(:invalid_params) do
      {
        analytics_summary: {
          metric_name: '',
          metric_type: 'invalid',
          metric_value: -5
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new analytics summary' do
        expect {
          post :create, params: valid_params
        }.to change(AnalyticsSummary, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created summary' do
        post :create, params: valid_params

        json_response = JSON.parse(response.body)
        expect(json_response['metric_name']).to eq('tasks_completed')
        expect(json_response['metric_type']).to eq('count')
        expect(json_response['metric_value']).to eq('42.5')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new analytics summary' do
        expect {
          post :create, params: invalid_params
        }.not_to change(AnalyticsSummary, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        post :create, params: invalid_params

        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('errors')
      end
    end
  end

  describe 'GET #dashboard' do
    let!(:task_summaries) { create_list(:analytics_summary, 3, metric_name: 'tasks_completed', time_period: 'daily') }
    let!(:user_summaries) { create_list(:analytics_summary, 2, metric_name: 'active_users', time_period: 'daily') }

    it 'returns dashboard data' do
      get :dashboard

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key('chart_data')
      expect(json_response).to have_key('summary_metrics')
      expect(json_response).to have_key('total_summaries')
      expect(json_response['total_summaries']).to eq(5)
    end

    context 'with period filter' do
      it 'returns dashboard data for specified period' do
        get :dashboard, params: { period: 'daily' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('period')
        expect(json_response['period']).to eq('daily')
      end
    end
  end

  describe 'GET #chart_data' do
    let!(:chart_summaries) { create_list(:analytics_summary, 5, metric_name: 'tasks_completed') }

    it 'returns chart-compatible data' do
      get :chart_data

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to be_an(Array)
      expect(json_response.length).to eq(5)

      first_item = json_response.first
      expect(first_item).to have_key('name')
      expect(first_item).to have_key('value')
      expect(first_item).to have_key('period')
      expect(first_item).to have_key('date')
    end

    context 'with metric filter' do
      it 'returns filtered chart data' do
        get :chart_data, params: { metric_name: 'tasks_completed' }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.all? { |item| item['name'] == 'tasks_completed' }).to be true
      end
    end
  end
end
