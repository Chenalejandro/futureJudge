class IsolateJob < ApplicationJob
  queue_as :default

  after_perform do |job|
    submission = job.arguments.first
    if ENV['TEST_ENV'] == 'true'
      svix = Svix::Client.new(ENV['SVIX_API_KEY'], Svix::SvixOptions.new(false, ENV['SVIX_SERVER_URL']))
      svix.application.get_or_create(Svix::ApplicationIn.new({
        "name": ENV['SVIX_SOLID_CODE_APP_NAME'],
        "rate_limit": nil,
        "uid": ENV['SVIX_SOLID_CODE_APP_ID']
      }))
      endpoint = svix.endpoint.create(ENV['SVIX_SOLID_CODE_APP_ID'], Svix::EndpointIn.new({
        "url": "http://host.docker.internal:3000/api/webhooks/submission",
        "description": "Solid Code submission result"
      }))
      message_out = svix.message.create(ENV['SVIX_SOLID_CODE_APP_ID'], Svix::MessageIn.new({
        "event_type": "submission.result",
        "payload": {
          result: Base64Service.encode(submission.result),
          status: submission.status,
          stderr: Base64Service.encode(submission.stderr),
          stdout: Base64Service.encode(submission.stdout),
          public_id: submission.public_id,
          message: Base64Service.encode(submission.message),
          compile_output: Base64Service.encode(submission.compile_output),
          memory: submission.memory,
          time: submission.time
        }
      }))
    else
      svix = Svix::Client.new(ENV['SVIX_AUTH_TOKEN'])
      message_out = svix.message.create(ENV['SVIX_SOLID_CODE_APP_ID'], Svix::MessageIn.new({
        "event_type": "submission.result",
        "payload": {
          result: Base64Service.encode(submission.result),
          status: submission.status,
          stderr: Base64Service.encode(submission.stderr),
          stdout: Base64Service.encode(submission.stdout),
          public_id: submission.public_id,
          message: Base64Service.encode(submission.message),
          compile_output: Base64Service.encode(submission.compile_output),
          memory: submission.memory,
          time: submission.time
        }
      }))
    end

  end

  STDIN_FILE_NAME = "stdin.txt"
  STDOUT_FILE_NAME = "stdout.txt"
  STDERR_FILE_NAME = "stderr.txt"
  METADATA_FILE_NAME = "metadata.txt"
  RESULT_FILE_NAME = "result.txt"

  # def perform(submission_id)
  #   submission = Submission.find(submission_id)
  #   submission.update(status: Submission.statuses[:processing], started_at: DateTime.now, execution_host: ENV["HOSTNAME"])
  #
  #   time = []
  #   memory = []
  #
  #   submission.number_of_runs.times do
  #     isolate_job_data = initialize_workdir(submission)
  #     if compile(submission, isolate_job_data) == :failure
  #       cleanup(isolate_job_data)
  #       return
  #     end
  #     run
  #     verify
  #
  #     time << submission.time
  #     memory << submission.memory
  #
  #     cleanup(isolate_job_data)
  #     break unless submission.accepted?
  #   end
  #
  #   submission.time = time.inject(&:+).to_f / time.size
  #   submission.memory = memory.inject(&:+).to_f / memory.size
  #   submission.save
  #
  # rescue Exception => e
  #   raise e.message unless submission
  #   submission.update(message: e.message, status: Submission.statuses[:boxerr], finished_at: DateTime.now)
  #   cleanup(isolate_job_data, raise_exception = false)
  # ensure
  #   call_callback
  # end

  def perform(submission)
    submission.update(status: Submission.statuses[:processing], started_at: DateTime.now, execution_host: ENV["HOSTNAME"])

    isolate_job_data = initialize_workdir(submission)
    if compile(submission, isolate_job_data) == :failure
      cleanup(isolate_job_data)
      return
    end
    run(submission, isolate_job_data)
    verify(submission, isolate_job_data)

    cleanup(isolate_job_data)

    submission.save

  rescue Exception => e
    submission.update(message: e.message, status: Submission.statuses[:boxerr], finished_at: DateTime.now)
    cleanup(isolate_job_data, raise_exception = false)
    raise e.message
  end

  private

  def initialize_workdir(submission)
    box_id = submission.id%2147483647
    cgroups = (!submission.enable_per_process_and_thread_time_limit || !submission.enable_per_process_and_thread_memory_limit) ? "--cg" : ""
    workdir = `isolate #{cgroups} -b #{box_id} --init`.chomp
    box_root = "/box"
    boxdir = workdir + box_root
    tmpdir = workdir + "/tmp"
    source_file = boxdir + "/" + submission.language.source_file.to_s
    stdin_file = workdir + "/" + STDIN_FILE_NAME
    stdout_file = workdir + "/" + STDOUT_FILE_NAME
    stderr_file = workdir + "/" + STDERR_FILE_NAME
    metadata_file = workdir + "/" + METADATA_FILE_NAME
    result_file = boxdir + "/" + RESULT_FILE_NAME
    result_file_from_box_root = box_root + "/" + RESULT_FILE_NAME

    [stdin_file, stdout_file, stderr_file, metadata_file, result_file].each do |f|
      initialize_file(f)
    end
    File.open(source_file, "wb") { |f| f.write(submission.source_code) }
    File.open(stdin_file, "wb") { |f| f.write(submission.stdin) }

    {
      :boxdir => boxdir,
      :workdir => workdir,
      :cgroups => cgroups,
      :box_id => box_id,
      :metadata_file => metadata_file,
      :result_file => result_file,
      :result_file_from_box_root => result_file_from_box_root,
      :stdout_file => stdout_file,
      :stdin_file => stdin_file,
      :source_file => source_file,
      :stderr_file => stderr_file,
      :tmpdir => tmpdir
    }
  end

  def initialize_file(file)
    `sudo touch #{file} && sudo chown $(whoami): #{file}`
  end

  def compile(submission, isolate_job_data)
    return :success unless submission.language.compile_cmd

    compile_script = isolate_job_data[:boxdir] + "/" + "compile.sh"

    # gsub can be skipped if compile script is used, but is kept for additional security.
    compiler_options = submission.compiler_options.to_s.strip.encode("UTF-8", invalid: :replace).gsub(/[$&;<>|`]/, "")
    File.open(compile_script, "w") { |f| f.write("#{submission.language.compile_cmd % compiler_options}") }

    compile_output_file = isolate_job_data[:workdir] + "/" + "compile_output.txt"
    initialize_file(compile_output_file)

    command = "isolate #{isolate_job_data[:cgroups]} \
    -s \
    -b #{isolate_job_data[:box_id]} \
    -M #{isolate_job_data[:metadata_file]} \
    --stderr-to-stdout \
    -i /dev/null \
    -t #{Config::MAX_CPU_TIME_LIMIT} \
    -x 0 \
    -w #{Config::MAX_WALL_TIME_LIMIT} \
    -k #{Config::MAX_STACK_LIMIT} \
    -p#{Config::MAX_MAX_PROCESSES_AND_OR_THREADS} \
    #{submission.enable_per_process_and_thread_memory_limit ? "-m " : "--cg-mem="}#{Config::MAX_MEMORY_LIMIT} \
    -f #{Config::MAX_MAX_FILE_SIZE} \
    -E HOME=/tmp \
    -E OUTPUT_PATH=#{isolate_job_data[:result_file_from_box_root]} \
    -E PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\" \
    -E LANG -E LANGUAGE -E LC_ALL -E JUDGE0_HOMEPAGE -E JUDGE0_SOURCE_CODE -E JUDGE0_MAINTAINER -E JUDGE0_VERSION \
    -d /etc:noexec \
    --run \
    -- /bin/bash $(basename #{compile_script}) > #{compile_output_file} \
    "

    puts "[#{DateTime.now}] Compiling submission #{submission.public_id} (#{submission.id}):"
    puts command.gsub(/\s+/, " ")
    puts

    `#{command}`
    process_status = $?

    compile_output = File.read(compile_output_file)
    compile_output = nil if compile_output.empty?
    submission.compile_output = compile_output

    metadata = get_metadata(isolate_job_data[:metadata_file])

    reset_metadata_file(isolate_job_data[:metadata_file])

    files_to_remove = [compile_output_file]
    files_to_remove << compile_script
    files_to_remove.each do |f|
      `sudo rm -rf #{f}`
    end

    return :success if process_status.success?

    if metadata[:status] == "TO"
      submission.compile_output = "Compilation time limit exceeded."
    end

    submission.finished_at = DateTime.now
    submission.time = nil
    submission.wall_time = nil
    submission.memory = nil
    submission.stdout = nil
    submission.stderr = nil
    submission.exit_code = nil
    submission.exit_signal = nil
    submission.message = nil
    submission.status = Submission.statuses[:compilation_error]
    submission.save

    :failure
  end

  def get_metadata(metadata_file)
    File.read(metadata_file).split("\n").collect do |e|
      { e.split(":").first.to_sym => e.split(":")[1..-1].join(":") }
    end.reduce({}, :merge)
  end

  def reset_metadata_file(metadata_file)
    `sudo rm -rf #{metadata_file}`
    initialize_file(metadata_file)
  end

  def cleanup(isolate_job_data, raise_exception = true)
    fix_permissions(isolate_job_data)
    `sudo rm -rf #{isolate_job_data[:boxdir]}/* #{isolate_job_data[:tmpdir]}/*`
    [isolate_job_data[:stdin_file], isolate_job_data[:stdout_file], isolate_job_data[:stderr_file], isolate_job_data[:metadata_file]].each do |f|
      `sudo rm -rf #{f}`
    end
    `isolate #{isolate_job_data[:cgroups]} -b #{isolate_job_data[:box_id]} --cleanup`
    raise "Cleanup of sandbox #{isolate_job_data[:box_id]} failed." if raise_exception && Dir.exist?(isolate_job_data[:workdir])
  end

  def fix_permissions(isolate_job_data)
    `sudo chown -R $(whoami): #{isolate_job_data[:boxdir]}`
  end


  def run(submission, isolate_job_data)
    run_script = isolate_job_data[:boxdir] + "/" + "run.sh"

    acceptable_project_run_scripts = [run_script, isolate_job_data[:boxdir] + "/" + "run"]
    acceptable_project_run_scripts.each do |f|
      if File.file?(f)
        run_script = f
        break
      end
    end


    # gsub is mandatory!
    command_line_arguments = submission.command_line_arguments.to_s.strip.encode("UTF-8", invalid: :replace).gsub(/[$&;<>|`]/, "")
    File.open(run_script, "w") { |f| f.write("#{submission.language.run_cmd} #{command_line_arguments}")}


    command = "isolate #{isolate_job_data[:cgroups]} \
    -s \
    -b #{isolate_job_data[:box_id]} \
    -M #{isolate_job_data[:metadata_file]} \
    #{submission.enable_network ? "--share-net" : ""} \
    -t #{submission.cpu_time_limit} \
    -x #{submission.cpu_extra_time} \
    -w #{submission.wall_time_limit} \
    -k #{submission.stack_limit} \
    -p#{submission.max_processes_and_or_threads} \
    #{submission.enable_per_process_and_thread_memory_limit ? "-m " : "--cg-mem="}#{submission.memory_limit} \
    -f #{submission.max_file_size} \
    -E HOME=/tmp \
    -E OUTPUT_PATH=#{isolate_job_data[:result_file_from_box_root]} \
    -E PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\" \
    -E LANG -E LANGUAGE -E LC_ALL -E JUDGE0_HOMEPAGE -E JUDGE0_SOURCE_CODE -E JUDGE0_MAINTAINER -E JUDGE0_VERSION \
    -d /etc:noexec \
    --run \
    -- /bin/bash $(basename #{run_script}) \
    < #{isolate_job_data[:stdin_file]} > #{isolate_job_data[:stdout_file]} 2> #{isolate_job_data[:stderr_file]} \
    "

    puts "[#{DateTime.now}] Running submission #{submission.public_id} (#{submission.id}):"
    puts command.gsub(/\s+/, " ")
    puts

    `#{command}`

    `sudo rm #{run_script}`
  end

  def verify(submission, isolate_job_data)
    submission.finished_at = DateTime.now

    metadata = get_metadata(isolate_job_data[:metadata_file])

    program_stdout = File.read(isolate_job_data[:stdout_file])
    program_stdout = nil if program_stdout.empty?

    program_result = File.read(isolate_job_data[:result_file])
    program_result = nil if program_result.empty?

    program_stderr = File.read(isolate_job_data[:stderr_file])
    program_stderr = nil if program_stderr.empty?

    submission.time = metadata[:time]
    submission.wall_time = metadata[:"time-wall"]
    submission.memory = (isolate_job_data[:cgroups].present? ? metadata[:"cg-mem"] : metadata[:"max-rss"])
    submission.stdout = program_stdout
    submission.stderr = program_stderr
    submission.result = program_result
    submission.exit_code = metadata[:exitcode].try(:to_i) || 0
    submission.exit_signal = metadata[:exitsig].try(:to_i)

    submission.message = metadata[:message]
    submission.status = determine_submission_status(metadata[:status], submission)

    # After adding support for compiler_options and command_line_arguments
    # status "Exec Format Error" will no longer occur because compile and run
    # is done inside a dynamically created bash script, thus isolate doesn't call
    # execve directily on submission.language.compile_cmd or submission.langauge.run_cmd.
    # Consequence of running compile and run through bash script is that when
    # target binary is not found then submission gets status "Runtime Error (NZEC)".
    #
    # I think this is for now O.K. behaviour, but I will leave this if block
    # here until I am 100% sure that "Exec Format Error" can be deprecated.
    if submission.boxerr? &&
      (
        submission.message.to_s.match(/^execve\(.+\): Exec format error$/) ||
          submission.message.to_s.match(/^execve\(.+\): No such file or directory$/) ||
          submission.message.to_s.match(/^execve\(.+\): Permission denied$/)
      )
      submission.status = :exeerr
    end
  end

  def determine_submission_status(metadata_status, submission)
    if metadata_status == "TO"
      :time_limit_exceeded
    elsif metadata_status == "SG"
      find_submission_status_by(submission.exit_signal)
    elsif metadata_status == "RE"
      :non_zero_exit_code
    elsif metadata_status == "XX"
      :boxerr
    else
      :accepted
    end
  end

  def find_submission_status_by(exit_signal)
    case exit_signal.to_i
    when 11 then :sig_segv
    when 25 then :sig_xfsz
    when 8  then :sig_fpe
    when 6  then :sig_abrt
    else :runtime_error
    end
  end

  def strip(text)
    return nil unless text
    text.split("\n").collect(&:rstrip).join("\n").rstrip
  # rescue ArgumentError
  #   return text
  end
end
