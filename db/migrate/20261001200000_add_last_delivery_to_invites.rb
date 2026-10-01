class AddLastDeliveryToInvites < ActiveRecord::Migration[8.1]
  def change
    add_column :invites, :last_delivery, :string, null: false, default: "sent"
  end
end
