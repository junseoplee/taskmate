require "rails_helper"

RSpec.describe Task, type: :model do
  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:user_id) }
    it { should validate_length_of(:title).is_at_least(1).is_at_most(255) }
    it { should validate_length_of(:description).is_at_most(2000) }
    
    it { should validate_inclusion_of(:status).in_array(%w[pending in_progress completed cancelled]) }
    it { should validate_inclusion_of(:priority).in_array(%w[low medium high urgent]) }
  end

  describe "default values" do
    let(:task) { build(:task) }

    it "sets default status to pending" do
      new_task = Task.new(title: "Test task", user_id: 1)
      expect(new_task.status).to eq("pending")
    end

    it "sets default priority to medium" do
      new_task = Task.new(title: "Test task", user_id: 1)
      expect(new_task.priority).to eq("medium")
    end
  end

  describe "scopes" do
    let!(:pending_task) { create(:task, status: "pending") }
    let!(:completed_task) { create(:task, status: "completed") }
    let!(:high_priority_task) { create(:task, priority: "high") }
    let!(:low_priority_task) { create(:task, priority: "low") }

    describe ".by_status" do
      it "returns tasks with given status" do
        expect(Task.by_status("pending")).to include(pending_task)
        expect(Task.by_status("pending")).not_to include(completed_task)
      end
    end

    describe ".by_priority" do
      it "returns tasks with given priority" do
        expect(Task.by_priority("high")).to include(high_priority_task)
        expect(Task.by_priority("high")).not_to include(low_priority_task)
      end
    end

    describe ".by_user" do
      let!(:user1_task) { create(:task, user_id: 1) }
      let!(:user2_task) { create(:task, user_id: 2) }

      it "returns tasks for given user" do
        expect(Task.by_user(1)).to include(user1_task)
        expect(Task.by_user(1)).not_to include(user2_task)
      end
    end

    describe ".due_soon" do
      let!(:due_today) { create(:task, due_date: Date.current) }
      let!(:due_tomorrow) { create(:task, due_date: 1.day.from_now) }
      let!(:due_next_week) { create(:task, due_date: 1.week.from_now) }

      it "returns tasks due within 3 days" do
        expect(Task.due_soon).to include(due_today, due_tomorrow)
        expect(Task.due_soon).not_to include(due_next_week)
      end
    end

    describe ".overdue" do
      let!(:overdue_task) { create(:task, due_date: 1.day.ago) }
      let!(:future_task) { create(:task, due_date: 1.day.from_now) }

      it "returns tasks past due date" do
        expect(Task.overdue).to include(overdue_task)
        expect(Task.overdue).not_to include(future_task)
      end
    end
  end

  describe "instance methods" do
    let(:task) { create(:task) }

    describe "#overdue?" do
      it "returns true for tasks past due date" do
        task.update!(due_date: 1.day.ago)
        expect(task.overdue?).to be true
      end

      it "returns false for tasks with future due date" do
        task.update!(due_date: 1.day.from_now)
        expect(task.overdue?).to be false
      end

      it "returns false for tasks without due date" do
        task.update!(due_date: nil)
        expect(task.overdue?).to be false
      end
    end

    describe "#due_soon?" do
      it "returns true for tasks due within 3 days" do
        task.update!(due_date: 2.days.from_now)
        expect(task.due_soon?).to be true
      end

      it "returns false for tasks due in more than 3 days" do
        task.update!(due_date: 5.days.from_now)
        expect(task.due_soon?).to be false
      end
    end

    describe "#completed?" do
      it "returns true for completed tasks" do
        task.update_column(:status, "completed")
        expect(task.completed?).to be true
      end

      it "returns false for non-completed tasks" do
        expect(task.completed?).to be false
      end
    end

    describe "#can_transition_to?" do
      context "from pending status" do
        let(:task) { create(:task, status: "pending") }

        it "can transition to in_progress" do
          expect(task.can_transition_to?("in_progress")).to be true
        end

        it "can transition to cancelled" do
          expect(task.can_transition_to?("cancelled")).to be true
        end

        it "cannot transition to completed" do
          expect(task.can_transition_to?("completed")).to be false
        end
      end

      context "from in_progress status" do
        let(:task) { create(:task, status: "in_progress") }

        it "can transition to completed" do
          expect(task.can_transition_to?("completed")).to be true
        end

        it "can transition to cancelled" do
          expect(task.can_transition_to?("cancelled")).to be true
        end

        it "can transition back to pending" do
          expect(task.can_transition_to?("pending")).to be true
        end
      end

      context "from completed status" do
        let(:task) { create(:task, status: "completed") }

        it "can only transition to pending for reopening" do
          expect(task.can_transition_to?("pending")).to be true
        end

        it "cannot transition to in_progress" do
          expect(task.can_transition_to?("in_progress")).to be false
        end

        it "cannot transition to cancelled" do
          expect(task.can_transition_to?("cancelled")).to be false
        end
      end
    end

    describe "#update_status!" do
      let(:task) { create(:task, status: "pending") }

      it "updates status when transition is valid" do
        expect(task.update_status!("in_progress")).to be true
        expect(task.reload.status).to eq("in_progress")
      end

      it "sets completed_at when transitioning to completed" do
        task.update_status!("in_progress")
        task.update_status!("completed")
        expect(task.reload.completed_at).to be_present
      end

      it "clears completed_at when transitioning away from completed" do
        task.update_status!("in_progress")
        task.update_status!("completed")
        task.update_status!("pending")
        expect(task.reload.completed_at).to be_nil
      end

      it "raises error when transition is invalid" do
        expect {
          task.update_status!("completed")
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "callbacks" do
    describe "before_validation" do
      it "strips whitespace from title" do
        task = create(:task, title: "  Test Task  ")
        expect(task.title).to eq("Test Task")
      end

      it "strips whitespace from description" do
        task = create(:task, description: "  Test Description  ")
        expect(task.description).to eq("Test Description")
      end
    end
  end
end