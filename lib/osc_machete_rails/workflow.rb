module OscMacheteRails
  # A plugin to maintain a workflow for Jobs.
  module Workflow

    # Registers a workflow relationship and sets up a hook to additional builder methods.
    #
    # @param [Symbol] jobs_active_record_relation_symbol The Job Identifier
    def has_machete_workflow_of(jobs_active_record_relation_symbol)
      # yes, this is magic mimicked from http://guides.rubyonrails.org/plugins.html
      #  and http://yehudakatz.com/2009/11/12/better-ruby-idioms/
      cattr_accessor :jobs_active_record_relation_symbol
      self.jobs_active_record_relation_symbol = jobs_active_record_relation_symbol

      # separate modules to group common methods for readability purposes
      # both builder methods and status methods need the jobs relation so
      # we include that first
      self.send :extend,  OscMacheteRails::Workflow::DSLMethods
      self.send :include, OscMacheteRails::Workflow::JobsRelation
      self.send :include, OscMacheteRails::Workflow::BuilderMethods
      self.send :include, OscMacheteRails::Workflow::StatusMethods
    end

    # The module defining the DSL methods used to interact with jobs
    module DSLMethods
      def defined_jobs
        @_jobs
      end

      def add_job(key, script, opts = {})
        @_jobs ||= {}
        @_jobs[key] = {script: script, opts: opts}
      end
    end

    # The module defining the active record relation of the jobs
    module JobsRelation
      # Assign the active record relation of this instance to the
      def jobs_active_record_relation
        self.send self.class.jobs_active_record_relation_symbol
      end
    end

    # depends on jobs_active_record_relation being defined
    module BuilderMethods

      # Returns the name of the class with underscores.
      #
      # @example Underscore a class
      #   FlowratePerformanceRun => flowrate_performance_run
      #
      # @return [String] The template name
      def staging_template_name
        self.class.name.underscore
      end

      # Returns the name of a staging directory that has been underscored and pluralized.
      #
      # @example
      #   Simulation => simulations
      # @example
      #   FlowratePerformanceRun => flowrate_performance_runs
      #
      # @return [String] The staging template directory name
      def staging_target_dir_name
        staging_template_name.pluralize
      end

      # Gets the staging target directory path.
      # Joins the AwesimRails.dataroot and the staging target directory name.
      #
      # @raise [Exception] "override staging_target_dir or include awesim_rails gem"
      #
      # @return [String] The staging target directory path.
      def staging_target_dir
        raise "override staging_target_dir or include awesim_rails gem" unless defined? AwesimRails
        AwesimRails.dataroot.join(staging_target_dir_name)
      end

      # Gets the staging template directory path.
      # Joins the { rails root }/jobs/{ staging_template_name } into a path.
      #
      # @return [String] The staging template directory path.
      def staging_template_dir
        Rails.root.join("jobs", staging_template_name)
      end

      # Creates a new staging target job directory on the system
      # Copies the staging template directory to the staging target job directory
      #
      # @return [String] The staged directory path.
      def stage
        staged_dir = OSC::Machete::JobDir.new(staging_target_dir).new_jobdir
        FileUtils.mkdir_p staged_dir
        FileUtils.cp_r staging_template_dir.to_s + "/.", staged_dir

        staged_dir
      end

      # Creates a new location and renders the mustache files
      #
      # @param [String] staged_dir The staging target directory path.
      # @param [Hash] template_view The template options to be rendered.
      #
      # @return [Location] The location of the staged and rendered template.
      def render_mustache_files(staged_dir, template_view)
        OSC::Machete::Location.new(staged_dir).render(template_view)
      end

      # Actions to perform after staging
      #
      # @param [String] staged_dir The staged directory path.
      def after_stage(staged_dir)
      end

      # Unimplemented method for building jobs.
      #
      # @param [String] staged_dir The staged directory path.
      # @param [Array, Nil] jobs An array of jobs to be built.
      #
      # @raise [NotImplementedError] The method is currently not implemented
      def build_jobs(staged_dir, job_list = [])
        _jobs = self.class.defined_jobs

        # Build array of jobs
        _jobs.each do |key, job_hash|
          script = staged_dir.join(job_hash[:script])
          job_hash[:_job] = OSC::Machete::Job.new(script: script)
          job_list << job_hash[:_job]
        end

        # Add dependencies
        _jobs.each do |key, job_hash|
          job_hash[:opts].fetch(:depend, {}).each do |method, job_keys|
            list = [*job_keys].map { |job_key| _jobs[job_key][:_job] }
            job_hash[:_job].send(method, list)
          end
        end

        job_list
      end

      # Call the #submit method on each job in a hash.
      #
      # @param [Hash] jobs A Hash of Job objects to be submitted.
      def submit_jobs(jobs)
        jobs.each(&:submit)
      end

      # Saves a Hash of jobs to a staged directory
      #
      # @param [Hash] jobs A Hash of Job objects to be saved.
      # @param [Location] staged_dir The staged directory as Location object.
      def save_jobs(jobs, staged_dir)
        self.staged_dir = staged_dir.to_s if self.respond_to?(:staged_dir=)
        self.save if self.id.nil? || self.respond_to?(:staged_dir=)

        jobs.each do |job|
          self.jobs_active_record_relation.create(job: job)
        end
      end

      # Perform the submit actions.
      #
      # Sets the staged_dir
      # Renders the mustache files.
      # Calls after_stage.
      # Calls build_jobs.
      # Submits the jobs.
      # Saves the jobs.
      #
      # @param [Hash, nil] template_view (self) The template options to be rendered.
      def submit(template_view=self)
        staged_dir = stage
        render_mustache_files(staged_dir, template_view)
        after_stage(staged_dir)
        jobs = build_jobs(staged_dir)
        submit_jobs(jobs)
        save_jobs(jobs, staged_dir)
      end
    end

    # depends on jobs_active_record_relation being defined
    module StatusMethods
      delegate :submitted?, :completed?, :failed?, :active?, to: :status

      # Reduce the jobs to a single OSC::Machete:Status value
      #
      # Assumes `jobs_active_record_relation` is a Statusable ActiveRecord
      # model. Get array of status values (one for each job) and then add them
      # together to get one value. OSC::Machete::Status#+ is overridden to 
      # return the highest precendent status value when adding two together.
      #
      # FIXME: it might be clearer in code to use `max` instead of `+` i.e.
      # statuses.reduce(&:max) and rename OSC::Machete::Status#+.
      #
      # @return [OSC::Machete::Status] a single value representing the status 
      def status
        statuses = jobs_active_record_relation.to_a.map(&:status)
        statuses.empty? ? OSC::Machete::Status.not_submitted : statuses.reduce(&:+)
      end
    end

    # extend Active Record with the has_workflow_of method
    ActiveRecord::Base.extend OscMacheteRails::Workflow if defined? ActiveRecord::Base
  end
end
