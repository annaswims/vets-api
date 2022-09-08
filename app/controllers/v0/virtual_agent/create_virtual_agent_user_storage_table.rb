class CreateVirtualAgentUserStorageTable < ActiveRecord::Migration[6.0]
  private def run
    create_table :virtual_agent_storage_blobs do |t|
      t.string :action_type, null: false
      t.string :first_name
      t.string :last_name
      t.string :ssan, null: false
      t.string :icn,  null: false
      t.datetime :created_at,  null: false

      t.index [ :ssan ], unique: false
      t.index [ :icn ],  unique: false
      t.index [ :created_at ], unique: false
    end
  end
end
