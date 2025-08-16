require 'rails_helper'

RSpec.describe Session, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:session) }
    
    it { should validate_uniqueness_of(:token) }
    
    it 'validates presence of token after skipping callbacks' do
      session = Session.new(user: create(:user))
      session.save(validate: false)  # 콜백 실행
      session.token = nil
      expect(session).not_to be_valid
      expect(session.errors[:token]).to include("can't be blank")
    end
    
    it 'validates presence of expires_at after skipping callbacks' do
      session = Session.new(user: create(:user))
      session.save(validate: false)  # 콜백 실행
      session.expires_at = nil
      expect(session).not_to be_valid
      expect(session.errors[:expires_at]).to include("can't be blank")
    end
  end

  describe 'callbacks' do
    describe 'before_create :generate_token' do
      it 'generates a unique token when token is blank' do
        user = create(:user)
        session = Session.new(user: user, expires_at: 24.hours.from_now)
        
        expect(session.token).to be_blank
        session.save!
        expect(session.token).to be_present
        expect(session.token.length).to eq(36) # UUID length
      end
    end

    describe 'before_create :set_expiry' do
      it 'sets expiry time to 24 hours from now' do
        travel_to Time.current do
          session = create(:session)
          expect(session.expires_at).to be_within(1.second).of(24.hours.from_now)
        end
      end
    end
  end

  describe 'scopes' do
    let!(:valid_session) { create(:session, expires_at: 1.hour.from_now) }
    let!(:expired_session) { create(:session, expires_at: 1.hour.ago) }

    describe '.valid' do
      it 'returns only non-expired sessions' do
        expect(Session.valid).to include(valid_session)
        expect(Session.valid).not_to include(expired_session)
      end
    end

    describe '.expired' do
      it 'returns only expired sessions' do
        expect(Session.expired).to include(expired_session)
        expect(Session.expired).not_to include(valid_session)
      end
    end
  end

  describe 'instance methods' do
    describe '#valid_session?' do
      it 'returns true for non-expired session' do
        session = create(:session, expires_at: 1.hour.from_now)
        expect(session.valid_session?).to be true
      end

      it 'returns false for expired session' do
        session = create(:session, expires_at: 1.hour.ago)
        expect(session.valid_session?).to be false
      end
    end

    describe '#extend_expiry!' do
      it 'extends session expiry by 24 hours' do
        session = create(:session)
        original_expiry = session.expires_at
        
        travel_to 1.hour.from_now do
          session.extend_expiry!
          expect(session.expires_at).to be > original_expiry
          expect(session.expires_at).to be_within(1.second).of(24.hours.from_now)
        end
      end
    end
  end

  describe 'cleanup' do
    describe '.cleanup_expired' do
      let!(:valid_sessions) { create_list(:session, 3, expires_at: 1.hour.from_now) }
      let!(:expired_sessions) { create_list(:session, 2, expires_at: 1.hour.ago) }

      it 'removes expired sessions only' do
        expect { Session.cleanup_expired }.to change { Session.count }.by(-2)
        expect(Session.all).to match_array(valid_sessions)
      end
    end
  end
end