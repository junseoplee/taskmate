require "rails_helper"

RSpec.describe Api::V1::AuthController, type: :controller do
  describe "POST #register" do
    let(:valid_params) do
      {
        name: "John Doe",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post :register, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates a session for the new user" do
        expect {
          post :register, params: valid_params
        }.to change(Session, :count).by(1)
      end

      it "returns success response with user data" do
        post :register, params: valid_params

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["user"]["name"]).to eq("John Doe")
        expect(json_response["user"]["email"]).to eq("john@example.com")
        expect(json_response["user"]).not_to have_key("password_digest")
      end

      it "sets session cookie" do
        post :register, params: valid_params

        expect(response.cookies["session_token"]).to be_present
        expect(response.cookies["session_token"]).to eq(Session.last.token)
      end
    end

    context "with invalid parameters" do
      it "returns validation errors for missing name" do
        invalid_params = valid_params.merge(name: "")
        post :register, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Name can't be blank")
      end

      it "returns validation errors for invalid email" do
        invalid_params = valid_params.merge(email: "invalid-email")
        post :register, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Email is invalid")
      end

      it "returns validation errors for weak password" do
        invalid_params = valid_params.merge(password: "123", password_confirmation: "123")
        post :register, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Password is too short (minimum is 8 characters)")
      end

      it "returns validation errors for password mismatch" do
        invalid_params = valid_params.merge(password_confirmation: "different")
        post :register, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Password confirmation doesn't match Password")
      end

      it "returns validation errors for duplicate email" do
        create(:user, email: "john@example.com")
        post :register, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Email has already been taken")
      end
    end
  end

  describe "POST #login" do
    let!(:user) { create(:user, email: "john@example.com", password: "password123", password_confirmation: "password123") }
    let(:valid_params) { { email: "john@example.com", password: "password123" } }

    context "with valid credentials" do
      it "creates a new session" do
        expect {
          post :login, params: valid_params
        }.to change(Session, :count).by(1)
      end

      it "returns success response with user data" do
        post :login, params: valid_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["user"]["id"]).to eq(user.id)
        expect(json_response["user"]["email"]).to eq("john@example.com")
        expect(json_response["user"]).not_to have_key("password_digest")
      end

      it "sets session cookie" do
        post :login, params: valid_params

        expect(response.cookies["session_token"]).to be_present
        expect(response.cookies["session_token"]).to eq(Session.last.token)
      end

      it "destroys existing session before creating new one" do
        existing_session = create(:session, user: user)
        expect(existing_session.reload).to be_persisted

        post :login, params: valid_params

        expect { existing_session.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(Session.count).to eq(1)
      end
    end

    context "with invalid credentials" do
      it "returns authentication error for wrong email" do
        invalid_params = valid_params.merge(email: "wrong@example.com")
        post :login, params: invalid_params

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "returns authentication error for wrong password" do
        invalid_params = valid_params.merge(password: "wrongpassword")
        post :login, params: invalid_params

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Invalid email or password")
      end

      it "does not create session for invalid credentials" do
        invalid_params = valid_params.merge(password: "wrongpassword")

        expect {
          post :login, params: invalid_params
        }.not_to change(Session, :count)
      end
    end
  end

  describe "POST #logout" do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }

    context "with valid session" do
      before do
        request.cookies["session_token"] = session.token
      end

      it "destroys the session" do
        expect {
          post :logout
        }.to change(Session, :count).by(-1)
      end

      it "returns success response" do
        post :logout

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("Logged out successfully")
      end

      it "clears session cookie" do
        post :logout

        expect(response.cookies["session_token"]).to be_nil
      end
    end

    context "without valid session" do
      it "returns unauthorized error" do
        post :logout

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("No session token provided")
      end
    end
  end

  describe "GET #verify" do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }

    context "with valid session" do
      before do
        request.cookies["session_token"] = session.token
      end

      it "returns user information" do
        get :verify

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["user"]["id"]).to eq(user.id)
        expect(json_response["user"]["email"]).to eq(user.email)
        expect(json_response["user"]).not_to have_key("password_digest")
      end

      it "extends session expiry" do
        original_expiry = session.expires_at
        get :verify

        expect(session.reload.expires_at).to be > original_expiry
      end
    end

    context "with expired session" do
      before do
        session.update!(expires_at: 1.hour.ago)
        request.cookies["session_token"] = session.token
      end

      it "returns unauthorized error" do
        get :verify

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Session expired")
      end

      it "destroys expired session" do
        expect {
          get :verify
        }.to change(Session, :count).by(-1)
      end
    end

    context "without session token" do
      it "returns unauthorized error" do
        get :verify

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("No session token provided")
      end
    end

    context "with invalid session token" do
      before do
        request.cookies["session_token"] = "invalid-token"
      end

      it "returns unauthorized error" do
        get :verify

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["error"]).to eq("Invalid session token")
      end
    end
  end
end
