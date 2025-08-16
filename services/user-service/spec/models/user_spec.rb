require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:sessions).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should have_secure_password }
    it { should validate_length_of(:password).is_at_least(8) }
  end

  describe 'email validation' do
    it 'accepts valid email formats' do
      valid_emails = %w[
        user@example.com
        test.user@domain.co.kr
        user+tag@example.org
      ]

      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid
      end
    end

    it 'rejects invalid email formats' do
      invalid_emails = %w[
        plainaddress
        @missingdomain.com
        missing@.com
        missing.domain@.com
      ]

      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end
    end
  end

  describe 'password security' do
    let(:user) { create(:user, password: 'SecurePass123!') }

    it 'stores encrypted password' do
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq('SecurePass123!')
    end

    it 'authenticates with correct password' do
      expect(user.authenticate('SecurePass123!')).to eq(user)
    end

    it 'fails authentication with incorrect password' do
      expect(user.authenticate('wrongpassword')).to be_falsey
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }

    describe '#full_name' do
      it 'returns the user name' do
        expect(user.full_name).to eq(user.name)
      end
    end

    describe '#active_session' do
      context 'with valid session' do
        let!(:session) { create(:session, user: user, expires_at: 1.hour.from_now) }

        it 'returns the active session' do
          expect(user.active_session).to eq(session)
        end
      end

      context 'without valid session' do
        it 'returns nil' do
          expect(user.active_session).to be_nil
        end
      end
    end
  end
end
