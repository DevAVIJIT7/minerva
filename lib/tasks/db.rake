# frozen_string_literal: true

require 'rake'

namespace :db do
  desc "Load stored procs"
  task load_minerva_functions: :environment do
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      p 'Loading db functions'
      sql = File.read('db/minerva_functions.sql')
      ActiveRecord::Base.transaction do
        conn.execute(sql)
      end
    end
  end
end

