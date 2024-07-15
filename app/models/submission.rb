class Submission < ApplicationRecord
  include PublicIdGenerator
  enum :status, {
    queued: 1, # In queue
    processing: 2, # Processing
    accepted: 3, # Accepted
    wrong_answer: 4, # Wrong Answer
    time_limit_exceeded: 5, # Time limit exceeded
    compilation_error: 6, # Compilation Error
    sig_segv: 7, # 'Runtime Error (SIGSEGV)'
    sig_xfsz: 8, # 'Runtime Error (SIGXFSZ)'
    sig_fpe: 9, # 'Runtime Error (SIGFPE)'
    sig_abrt: 10, # 'Runtime Error (SIGABRT)'
    non_zero_exit_code: 11, # 'Runtime Error (NZEC)'
    runtime_error: 12, # 'Runtime Error (Other)'
    boxerr: 13, # 'Internal Error'
    exeerr: 14 # 'Exec Format Error'
  }
  belongs_to :language

  validates :language_id, :source_code, presence: true
  validates :compiler_options, length: { maximum: 255 }
  validates :command_line_arguments, length: { maximum: 255 }
  validates :enable_per_process_and_thread_time_limit,
            inclusion: { in: [false], message: "this option cannot be enabled" },
            unless: -> { Config::ALLOW_ENABLE_PER_PROCESS_AND_THREAD_TIME_LIMIT }
  validates :enable_per_process_and_thread_memory_limit,
            inclusion: { in: [false], message: "this option cannot be enabled" },
            unless: -> { Config::ALLOW_ENABLE_PER_PROCESS_AND_THREAD_MEMORY_LIMIT }
  before_validation :set_defaults

  private
  def set_defaults
    self.status ||= :queued
    self.number_of_runs ||= Config::NUMBER_OF_RUNS
    self.cpu_time_limit ||= Config::CPU_TIME_LIMIT
    self.cpu_extra_time ||= Config::CPU_EXTRA_TIME
    self.wall_time_limit ||= Config::WALL_TIME_LIMIT
    self.memory_limit ||= Config::MEMORY_LIMIT
    self.stack_limit ||= Config::STACK_LIMIT
    self.max_processes_and_or_threads ||= Config::MAX_PROCESSES_AND_OR_THREADS
    self.enable_per_process_and_thread_time_limit = self.enable_per_process_and_thread_time_limit != nil ?
                                                      self.enable_per_process_and_thread_time_limit :
                                                      Config::ENABLE_PER_PROCESS_AND_THREAD_TIME_LIMIT
    self.enable_per_process_and_thread_memory_limit = self.enable_per_process_and_thread_memory_limit != nil ?
                                                        self.enable_per_process_and_thread_memory_limit :
                                                        Config::ENABLE_PER_PROCESS_AND_THREAD_MEMORY_LIMIT
    self.max_file_size ||= Config::MAX_FILE_SIZE
    self.enable_network = self.enable_network != nil ? self.enable_network : Config::ENABLE_NETWORK
  end
end
