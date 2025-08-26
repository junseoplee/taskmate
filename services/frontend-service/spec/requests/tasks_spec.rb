require 'rails_helper'

RSpec.describe "TasksController", type: :request do
  let(:mock_user) do
    {
      'id' => 2,
      'name' => '테스트 사용자',
      'email' => 'test@taskmate.com'
    }
  end
  
  let(:mock_tasks_response) do
    {
      'success' => true,
      'tasks' => [
        {
          'id' => 1,
          'title' => '프로젝트 마감 준비',
          'description' => '프로젝트 최종 점검 및 배포 준비 작업',
          'status' => 'in_progress',
          'priority' => 'high',
          'user_id' => 2,
          'due_date' => '2025-08-25',
          'created_at' => '2025-08-24T14:41:35.932Z',
          'updated_at' => '2025-08-24T14:41:35.932Z'
        },
        {
          'id' => 2,
          'title' => '긴급: 서버 보안 취약점 패치',
          'description' => '서버에서 발견된 보안 취약점을 즉시 패치해야 합니다.',
          'status' => 'pending',
          'priority' => 'high',
          'user_id' => 2,
          'due_date' => '2025-08-25',
          'created_at' => '2025-08-24T14:46:13.275Z',
          'updated_at' => '2025-08-24T14:46:13.275Z'
        }
      ],
      'total' => 2
    }
  end

  before do
    # 인증 우회 설정
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(mock_user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    
    # TaskServiceClient 모킹
    mock_client = instance_double(TaskServiceClient)
    allow(TaskServiceClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive(:get_user_tasks).and_return(mock_tasks_response)
  end

  describe "GET /tasks" do
    it "displays the tasks page" do
      get "/tasks"
      
      expect(response).to have_http_status(200)
      expect(response.body).to include("Task Management")
      expect(response.body).to include("프로젝트 마감 준비")
      expect(response.body).to include("긴급: 서버 보안 취약점 패치")
    end

    it "shows task details correctly" do
      get "/tasks"
      
      # 상태 표시 확인
      expect(response.body).to include("In Progress")
      expect(response.body).to include("Pending")
      
      # 우선순위 표시 확인
      expect(response.body).to include("High")
      
      # 날짜 표시 확인
      expect(response.body).to include("2025-08-25")
    end

    it "shows action buttons" do
      get "/tasks"
      
      # 뷰, 편집, 삭제 버튼 확인
      expect(response.body).to include('href="/tasks/1"')
      expect(response.body).to include('href="/tasks/1/edit"')
      expect(response.body).to include('data-confirm="Are you sure you want to delete this task?"')
    end
    
    it "shows New Task button" do
      get "/tasks"
      
      expect(response.body).to include("New Task")
      expect(response.body).to include('href="/tasks/new"')
    end
  end

  describe "when no tasks exist" do
    let(:empty_tasks_response) do
      {
        'success' => true,
        'tasks' => [],
        'total' => 0
      }
    end

    before do
      mock_client = instance_double(TaskServiceClient)
      allow(TaskServiceClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:get_user_tasks).and_return(empty_tasks_response)
    end

    it "shows empty state message" do
      get "/tasks"
      
      expect(response).to have_http_status(200)
      expect(response.body).to include("No tasks found")
      expect(response.body).to include("Start by creating your first task")
    end
  end

  describe "API error handling" do
    let(:error_response) do
      {
        'success' => false,
        'message' => 'Service unavailable'
      }
    end

    before do
      mock_client = instance_double(TaskServiceClient)
      allow(TaskServiceClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:get_user_tasks).and_return(error_response)
    end

    it "handles API errors gracefully" do
      get "/tasks"
      
      expect(response).to have_http_status(200)
      expect(response.body).to include("No tasks found")
    end
  end
end