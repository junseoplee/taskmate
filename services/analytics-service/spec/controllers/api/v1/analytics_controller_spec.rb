require 'rails_helper'

RSpec.describe Api::V1::AnalyticsController, type: :controller do
  describe "GET #dashboard" do
    it "returns dashboard statistics" do
      get :dashboard

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'total_tasks',
        'completed_tasks',
        'completion_rate',
        'pending_tasks',
        'in_progress_tasks',
        'high_priority_tasks',
        'overdue_tasks'
      )
    end

    it "returns numeric values for all stats" do
      get :dashboard

      json_response = JSON.parse(response.body)

      expect(json_response['total_tasks']).to be_a(Numeric)
      expect(json_response['completed_tasks']).to be_a(Numeric)
      expect(json_response['completion_rate']).to be_a(Numeric)
      expect(json_response['pending_tasks']).to be_a(Numeric)
      expect(json_response['in_progress_tasks']).to be_a(Numeric)
      expect(json_response['high_priority_tasks']).to be_a(Numeric)
      expect(json_response['overdue_tasks']).to be_a(Numeric)
    end
  end

  describe "GET #completion_rate" do
    it "returns completion rate statistics" do
      get :completion_rate

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'completion_rate',
        'total_tasks',
        'completed_tasks',
        'period'
      )
    end

    it "returns completion rate as percentage" do
      get :completion_rate

      json_response = JSON.parse(response.body)

      expect(json_response['completion_rate']).to be_a(Numeric)
      expect(json_response['completion_rate']).to be >= 0
      expect(json_response['completion_rate']).to be <= 100
    end
  end

  describe "GET #completion_trend" do
    it "returns completion trend data" do
      get :completion_trend

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'trend_data',
        'period',
        'generated_at'
      )
    end

    it "returns trend data as array" do
      get :completion_trend

      json_response = JSON.parse(response.body)

      expect(json_response['trend_data']).to be_a(Array)
      expect(json_response['trend_data'].length).to eq(30)

      # 각 데이터 포인트 구조 검증
      json_response['trend_data'].each do |data_point|
        expect(data_point).to include('date', 'completed_tasks')
        expect(data_point['date']).to match(/\d{4}-\d{2}-\d{2}/)
        expect(data_point['completed_tasks']).to be_a(Numeric)
      end
    end
  end

  describe "GET #priority_distribution" do
    it "returns priority distribution data" do
      get :priority_distribution

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'distribution',
        'total_tasks',
        'generated_at'
      )
    end

    it "returns distribution with high, medium, low priorities" do
      get :priority_distribution

      json_response = JSON.parse(response.body)
      distribution = json_response['distribution']

      expect(distribution).to include('high', 'medium', 'low')
      expect(distribution['high']).to be_a(Numeric)
      expect(distribution['medium']).to be_a(Numeric)
      expect(distribution['low']).to be_a(Numeric)
    end
  end

  describe "POST #create_event" do
    let(:valid_event_params) do
      {
        event: {
          event_type: 'task',
          user_id: 1,
          task_id: 1,
          data: { action: 'created', priority: 'high' }
        }
      }
    end

    let(:invalid_event_params) do
      {
        event: {
          event_type: '',
          user_id: nil
        }
      }
    end

    context "with valid parameters" do
      it "creates a new analytics event" do
        expect {
          post :create_event, params: valid_event_params
        }.to change(AnalyticsEvent, :count).by(1)
      end

      it "returns success response" do
        post :create_event, params: valid_event_params

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response).to have_key('event_id')
        expect(json_response).to have_key('message')
      end
    end

    context "with invalid parameters" do
      it "does not create analytics event" do
        expect {
          post :create_event, params: invalid_event_params
        }.not_to change(AnalyticsEvent, :count)
      end

      it "returns error response" do
        post :create_event, params: invalid_event_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response).to have_key('errors')
      end
    end
  end
end
