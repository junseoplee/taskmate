require 'rails_helper'

RSpec.describe Api::V1::TasksController, type: :controller do
  let(:valid_user_headers) {
    {
      'Authorization' => 'Bearer valid_token',
      'Content-Type' => 'application/json'
    }
  }
  let(:current_user) { { id: 1, name: "Test User", email: "test@example.com" } }

  before do
    # Mock successful authentication for all tests
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  describe "GET #index" do
    let!(:user_tasks) { create_list(:task, 3, user_id: 1) }
    let!(:other_user_tasks) { create_list(:task, 2, user_id: 2) }

    it "returns tasks for the current user only" do
      get :index

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['tasks'].length).to eq(3)
      expect(json_response['tasks'].all? { |task| task['user_id'] == 1 }).to be true
    end

    it "returns tasks filtered by status" do
      create(:task, user_id: 1, status: 'completed')

      get :index, params: { status: 'completed' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['tasks'].all? { |task| task['status'] == 'completed' }).to be true
    end

    it "returns tasks filtered by priority" do
      create(:task, user_id: 1, priority: 'high')

      get :index, params: { priority: 'high' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['tasks'].all? { |task| task['priority'] == 'high' }).to be true
    end

    it "returns overdue tasks" do
      create(:task, user_id: 1, due_date: 2.days.ago)

      get :index, params: { filter: 'overdue' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['tasks'].all? { |task| Date.parse(task['due_date']) < Date.current }).to be true
    end

    it "returns due soon tasks" do
      create(:task, user_id: 1, due_date: 2.days.from_now)

      get :index, params: { filter: 'due_soon' }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['tasks'].length).to be >= 1
    end
  end

  describe "GET #show" do
    let(:task) { create(:task, user_id: 1) }

    it "returns the task when user owns it" do
      get :show, params: { id: task.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['id']).to eq(task.id)
    end

    it "returns 404 when task belongs to different user" do
      other_task = create(:task, user_id: 2)

      get :show, params: { id: other_task.id }

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when task does not exist" do
      get :show, params: { id: 99999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) {
      {
        title: "New Task",
        description: "Task description",
        priority: "medium",
        due_date: 1.week.from_now.to_date
      }
    }

    it "creates a new task with valid attributes" do
      expect {
        post :create, params: { task: valid_attributes }
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['title']).to eq("New Task")
      expect(json_response['task']['user_id']).to eq(1)
      expect(json_response['task']['status']).to eq("pending")
    end

    it "returns error with invalid attributes" do
      invalid_attributes = { title: "", description: "No title" }

      post :create, params: { task: invalid_attributes }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to include("Title can't be blank")
    end

    it "sets user_id to current user" do
      post :create, params: { task: valid_attributes.merge(user_id: 999) }

      expect(response).to have_http_status(:created)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['user_id']).to eq(1)
    end
  end

  describe "PUT #update" do
    let(:task) { create(:task, user_id: 1, title: "Original Title") }

    it "updates task with valid attributes" do
      put :update, params: { id: task.id, task: { title: "Updated Title" } }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['title']).to eq("Updated Title")
      expect(task.reload.title).to eq("Updated Title")
    end

    it "returns error with invalid attributes" do
      put :update, params: { id: task.id, task: { title: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to include("Title can't be blank")
    end

    it "returns 404 when task belongs to different user" do
      other_task = create(:task, user_id: 2)

      put :update, params: { id: other_task.id, task: { title: "Hacked" } }

      expect(response).to have_http_status(:not_found)
    end

    it "prevents updating user_id" do
      put :update, params: { id: task.id, task: { user_id: 999 } }

      expect(response).to have_http_status(:ok)
      expect(task.reload.user_id).to eq(1)
    end
  end

  describe "DELETE #destroy" do
    let!(:task) { create(:task, user_id: 1) }

    it "deletes the task when user owns it" do
      expect {
        delete :destroy, params: { id: task.id }
      }.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 when task belongs to different user" do
      other_task = create(:task, user_id: 2)

      expect {
        delete :destroy, params: { id: other_task.id }
      }.not_to change(Task, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when task does not exist" do
      delete :destroy, params: { id: 99999 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH #update_status" do
    let(:task) { create(:task, user_id: 1, status: "pending") }

    it "updates task status with valid transition" do
      patch :update_status, params: { id: task.id, status: "in_progress" }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['status']).to eq("in_progress")
      expect(task.reload.status).to eq("in_progress")
    end

    it "returns error with invalid transition" do
      patch :update_status, params: { id: task.id, status: "completed" }

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to include(/Cannot transition/)
    end

    it "returns 404 when task belongs to different user" do
      other_task = create(:task, user_id: 2)

      patch :update_status, params: { id: other_task.id, status: "in_progress" }

      expect(response).to have_http_status(:not_found)
    end

    it "returns error when status parameter is missing" do
      patch :update_status, params: { id: task.id }

      expect(response).to have_http_status(:bad_request)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to include("Status parameter is required")
    end

    it "sets completed_at when transitioning to completed" do
      task.update_status!("in_progress")

      patch :update_status, params: { id: task.id, status: "completed" }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['task']['completed_at']).to be_present
    end
  end

  # Authentication tests
  describe "Authentication" do
    before do
      # Remove authentication mocking to test real authentication flow
      allow(controller).to receive(:authenticate_user!).and_call_original
      allow(controller).to receive(:current_user).and_call_original
    end

    it "returns 401 when not authenticated" do
      # Clear cookies to ensure no authentication
      request.cookies.clear

      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it "authenticates with valid session token" do
      # Set valid session token in cookies
      request.cookies[:session_token] = 'valid_token'

      get :index

      expect(response).to have_http_status(:ok)
    end
  end
end
