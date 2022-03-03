# frozen_string_literal: true

class UffizziCore::Deployment::DeleteDnsRecordJob < ApplicationJob
  sidekiq_options queue: :deployments, retry: 5

  def perform(preview_url)
    Rails.logger.info("DEPLOYMENT_PROCESS DeleteDnsRecordJob(preview_url:#{preview_url})")

    GoogleCloud::DnsService.delete_dns_record(preview_url)
  end
end
