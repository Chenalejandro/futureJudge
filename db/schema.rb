# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2024_09_03_001318) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "languages", force: :cascade do |t|
    t.string "name", null: false
    t.string "compile_cmd"
    t.string "run_cmd", null: false
    t.string "source_file", null: false
    t.boolean "is_archived", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "monaco_name", null: false
    t.integer "major", null: false
    t.integer "minor", null: false
    t.integer "patch", null: false
  end

  create_table "submissions", force: :cascade do |t|
    t.text "source_code", null: false
    t.bigint "language_id", null: false
    t.text "stdin"
    t.text "stdout"
    t.text "result"
    t.integer "status", null: false
    t.datetime "finished_at"
    t.decimal "time"
    t.integer "memory"
    t.text "stderr"
    t.integer "number_of_runs"
    t.decimal "cpu_time_limit"
    t.decimal "cpu_extra_time"
    t.decimal "wall_time_limit"
    t.integer "memory_limit"
    t.integer "stack_limit"
    t.integer "max_processes_and_or_threads"
    t.boolean "enable_per_process_and_thread_time_limit"
    t.boolean "enable_per_process_and_thread_memory_limit"
    t.integer "max_file_size"
    t.text "compile_output"
    t.integer "exit_code"
    t.integer "exit_signal"
    t.text "message"
    t.decimal "wall_time"
    t.string "compiler_options"
    t.string "command_line_arguments"
    t.boolean "redirect_stderr_to_stdout"
    t.string "callback_url"
    t.boolean "enable_network"
    t.datetime "started_at"
    t.datetime "queued_at"
    t.string "queue_host"
    t.string "execution_host"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "public_id", limit: 12, null: false
    t.index ["language_id"], name: "index_submissions_on_language_id"
    t.index ["public_id"], name: "index_submissions_on_public_id", unique: true
  end

  add_foreign_key "submissions", "languages", column: "language_id"
end
