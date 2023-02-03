# frozen_string_literal: true

module Coupons
  class DestroyService < BaseService
    def self.call(...)
      new(...).call
    end

    def initialize(coupon:)
      @coupon = coupon
      super
    end

    def call
      return result.not_found_failure!(resource: 'coupon') unless coupon

      ActiveRecord::Base.transaction do
        coupon.discard!
        coupon.coupon_plans.discard_all
      end

      result.coupon = coupon
      result
    end

    private

    attr_reader :coupon
  end
end
