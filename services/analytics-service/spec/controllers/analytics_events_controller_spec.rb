# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsEventsController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        analytics_event: {
          event_name: 'task.created',
          event_type: 'task',
          source_service: 'task-service',
          metadata: { task_id: 123, priority: 'high' },
          user_id: 1
        }
      }
    end

    let(:invalid_params) do
      {
        analytics_event: {
          event_name: '',
          event_type: 'invalid',
          source_service: ''
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new analytics event' do
        expect {
          post :create, params: valid_params
        }.to change(AnalyticsEvent, :count).by(1)
      end

      it 'returns created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns the created event' do
        post :create, params: valid_params
        
        json_response = JSON.parse(response.body)
        expect(json_response['event_name']).to eq('task.created')
        expect(json_response['event_type']).to eq('task')
        expect(json_response['source_service']).to eq('task-service')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new analytics event' do
        expect {
          post :create, params: invalid_params
        }.not_to change(AnalyticsEvent, :count)
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

  describe 'GET #index' do
    let!(:task_events) { create_list(:analytics_event, 3, event_type: 'task') }
    let!(:user_events) { create_list(:analytics_event, 2, event_type: 'user') }

    context 'without filters' do
      it 'returns all events' do
        get :index
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(5)
      end
    end

    context 'with event_type filter' do
      it 'returns filtered events' do
        get :index, params: { event_type: 'task' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(3)
        expect(json_response.all? { |event| event['event_type'] == 'task' }).to be true
      end
    end

    context 'with source_service filter' do
      it 'returns filtered events' do
        get :index, params: { source_service: 'task-service' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response.all? { |event| event['source_service'] == 'task-service' }).to be true
      end
    end

    context 'with date range filter' do
      let!(:today_events) { create_list(:analytics_event, 2, occurred_at: Time.current) }
      let!(:old_events) { create_list(:analytics_event, 1, occurred_at: 10.days.ago) }

      it 'returns events within date range' do
        start_date = Date.current.beginning_of_day
        end_date = Date.current.end_of_day
        
        get :index, params: { start_date: start_date, end_date: end_date }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        
        # Should include today events but not old events
        event_ids = json_response.map { |event| event['id'] }
        expect(event_ids).to include(*today_events.map(&:id))
        expect(event_ids).not_to include(*old_events.map(&:id))
      end
    end
  end

  describe 'GET #metrics' do
    let!(:task_events) { create_list(:analytics_event, 5, event_type: 'task') }
    let!(:user_events) { create_list(:analytics_event, 3, event_type: 'user') }

    it 'returns aggregated metrics' do
      get :metrics
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      
      expect(json_response).to have_key('total_events')
      expect(json_response).to have_key('events_by_type')
      expect(json_response).to have_key('events_by_service')
      expect(json_response['total_events']).to eq(8)
      expect(json_response['events_by_type']['task']).to eq(5)
      expect(json_response['events_by_type']['user']).to eq(3)
    end

    context 'with time period filter' do
      it 'returns metrics for specified period' do
        get :metrics, params: { period: 'today' }
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to have_key('period')
        expect(json_response['period']).to eq('today')
      end
    end
  end
end