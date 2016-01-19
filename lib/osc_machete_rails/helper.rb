module OscMacheteRails
  module Helper
    def job_status_label(job)
      job ||= OpenStruct.new status: OSC::Machete::Status.not_submitted
      text = job.status.inspect

      label_class = 'label-default'
      if job.failed?
        label_class = 'label-danger'
      elsif job.passed?
        label_class = 'label-success'
        text = "Completed"
      elsif job.active?
        label_class = 'label-primary'
      end

      content_tag :span, class: %I(label #{label_class}) do
        text
      end
    end
  end
end

ActionView::Base.send :include, OscMacheteRails::Helper
