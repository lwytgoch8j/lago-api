# frozen_string_literal: true

module Organizations
  class UpdateInvoiceGracePeriodService < BaseService
    def initialize(organization:, grace_period:)
      @organization = organization
      @grace_period = grace_period
      super
    end

    def call
      ActiveRecord::Base.transaction do
        organization.update!(invoice_grace_period: grace_period)

        # NOTE: Finalize related draft invoices.
        organization.invoices.ready_to_be_finalized.each do |invoice|
          Invoices::FinalizeService.call(invoice:)
        end

        # NOTE: Update issuing_date on draft invoices.
        organization.invoices.draft.each do |invoice|
          invoice.update!(issuing_date: grace_period_issuing_date(invoice))
        end

        result.organization = organization
        result
      end
    end

    private

    attr_reader :organization, :grace_period

    def invoice_created_at(invoice)
      invoice.created_at.in_time_zone(invoice.customer.applicable_timezone).to_date
    end

    def grace_period_issuing_date(invoice)
      invoice_created_at(invoice) + invoice.customer.applicable_invoice_grace_period.days
    end
  end
end
