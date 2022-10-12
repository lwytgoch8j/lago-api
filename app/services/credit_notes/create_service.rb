# frozen_string_literal: true

module CreditNotes
  class CreateService < BaseService
    def initialize(invoice:, items_attr:, reason: :other)
      @invoice = invoice
      @items_attr = items_attr
      @reason = reason

      super
    end

    def call
      ActiveRecord::Base.transaction do
        result.credit_note = CreditNote.create!(
          customer: invoice.customer,
          invoice: invoice,
          amount_currency: invoice.amount_currency,
          remaining_amount_currency: invoice.amount_currency,
          reason: reason,
        )

        create_items
        return result unless result.success?

        credit_note.update!(
          remaining_amount_cents: credit_note.amount_cents,
        )
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      result.record_validation_failure!(record: e.record)
    end

    private

    attr_accessor :invoice, :items_attr, :reason

    delegate :credit_note, to: :result

    def create_items
      items_attr.each do |item_attr|
        item = credit_note.items.new(
          fee: invoice.fees.find_by(id: item_attr[:fee_id]),
          credit_amount_cents: item_attr[:credit_amount_cents],
          credit_amount_currency: invoice.amount_currency,
        )
        break unless valid_item?(item)

        item.save!

        # NOTE: update credit note credit amount to allow validation on next item
        credit_note.update!(
          amount_cents: credit_note.amount_cents + item.credit_amount_cents,
        )
      end
    end

    def valid_item?(item)
      CreditNotes::ValidateItemService.new(result, item: item).valid?
    end
  end
end