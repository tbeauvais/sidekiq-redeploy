# frozen_string_literal: true

RSpec.describe Sidekiq::Redeploy do
  it 'has a version number' do
    expect(Sidekiq::Redeploy::VERSION).not_to be_nil
  end
end
