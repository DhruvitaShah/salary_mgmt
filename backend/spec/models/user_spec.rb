require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  it { is_expected.to be_valid }

  it "normalises the email" do
    u = build(:user, email: "  HR@Acme.COM ")
    u.validate
    expect(u.email).to eq("hr@acme.com")
  end

  it "requires a unique email regardless of case" do
    create(:user, email: "hr@acme.com")
    expect(build(:user, email: "HR@ACME.COM")).not_to be_valid
  end

  it "requires a password of at least 12 characters" do
    expect(build(:user, password: "short-pass")).not_to be_valid
    expect(build(:user, password: "long-enough-pass")).to be_valid
  end

  it "stores only a digest, never the password" do
    u = create(:user)
    expect(u.password_digest).to be_present
    expect(u.password_digest).not_to include(AuthHelpers::PASSWORD)
  end

  describe "lockout" do
    let(:user) { create(:user) }

    it "locks for 15 minutes after 5 failed attempts" do
      4.times { user.register_failed_attempt! }
      expect(user).not_to be_locked
      user.register_failed_attempt!
      expect(user).to be_locked
      expect(user.minutes_until_unlock).to eq(15)
    end

    it "unlocks once the time has passed" do
      5.times { user.register_failed_attempt! }
      travel_to(16.minutes.from_now) { expect(user).not_to be_locked }
    end

    it "clears the counter on a successful sign-in" do
      3.times { user.register_failed_attempt! }
      user.register_successful_sign_in!
      expect(user.reload).to have_attributes(failed_attempts: 0, locked_until: nil)
      expect(user.last_sign_in_at).to be_present
    end
  end
end
