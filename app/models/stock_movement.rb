class StockMovement < ApplicationRecord
  belongs_to :store, optional: true
  belongs_to :product
  belongs_to :purchase, optional: true
  belongs_to :invoice, optional: true

  enum movement_type: { in: 0, out: 1, adjust: 2 }
end
