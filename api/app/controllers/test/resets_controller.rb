module Test
  class ResetsController < ApplicationController
    requires_permission "test:reset", only: :create

    def create
      raise "test-only endpoint" unless Rails.env.test?
      Test::DatabaseReset.call
      head :no_content
    end
  end
end
