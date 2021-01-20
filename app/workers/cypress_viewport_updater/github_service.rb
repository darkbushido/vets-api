# frozen_string_literal: true

module CypressViewportUpdater
  class GithubService
    data = YAML.safe_load(File.open('config/settings.local.yml'))
    ACCESS_TOKEN = data['github_cypress_viewport_updater_bot']['access_token']
    REPO = 'holdenhinkle/vets-website'

    attr_reader :client, :feature_branch_name

    def initialize
      @client = Octokit::Client.new(access_token: ACCESS_TOKEN)
    end

    def get_content(file)
      file.sha = client.content(REPO, path: file.github_path).sha
      file.raw_content = client.content(REPO, path: file.github_path, accept: 'application/vnd.github.V3.raw')
    end

    def create_branch
      set_feature_branch_name
      ref = "heads/#{feature_branch_name}"
      sha = client.ref(REPO, 'heads/master').object.sha
      client.create_ref(REPO, ref, sha)
    end

    def update_content(file, content)
      client.update_content(REPO,
                            file.github_path,
                            "update #{file.name}",
                            file.sha,
                            content,
                            branch: feature_branch_name)
    end

    def submit_pr
      client.create_pull_request(REPO,
                                 'master',
                                 feature_branch_name,
                                 'Update Cypress Viewport Data (Automatic Update)')
    end

    private

    attr_writer :feature_branch_name

    def set_feature_branch_name
      prefix = DateTime.now.strftime('%m%d%Y%H%M%S%L')
      name = 'update_cypress_viewport_data'
      self.feature_branch_name = prefix + '_' + name
    end
  end
end
