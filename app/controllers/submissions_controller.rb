class SubmissionsController < AuthenticationController

  def show
    public_id = params[:public_id]
    render json: Rails.cache.fetch("#{public_id}", expires_in: Config::SUBMISSION_CACHE_DURATION, race_condition_ttl: 0.1*Config::SUBMISSION_CACHE_DURATION) {
      Submission.find_by!(public_id: public_id)
    }, fields: [:public_id, :stdout, :stderr, :result, :message, :status, :compile_output]
  end

  def create
    submission = Submission.new(get_submission_params(params))

    if submission.save
      IsolateJob.perform_later(submission)
      render json: submission, status: :created, fields: [:public_id, :status]
    else
      render json: submission.errors, status: :unprocessable_entity
    end
  end

  private

    def get_submission_params(params)
      submission_params = params.require(:submission).permit(
        :source_code,
        :language_id,
        :compiler_options,
        :command_line_arguments,
        :number_of_runs,
        :stdin,
        :cpu_time_limit,
        :cpu_extra_time,
        :wall_time_limit,
        :memory_limit,
        :stack_limit,
        :max_processes_and_or_threads,
        :enable_per_process_and_thread_time_limit,
        :enable_per_process_and_thread_memory_limit,
        :max_file_size,
        :callback_url,
        :enable_network
      )
      submission_params[:source_code] = Base64Service.decode(submission_params[:source_code])
      submission_params[:stdin] = Base64Service.decode(submission_params[:stdin])

      submission_params
    end
end
