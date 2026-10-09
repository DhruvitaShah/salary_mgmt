Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :employees, only: %i[index show create update]
      resource :session, only: %i[show create destroy]
      resource :lookups, only: :show
      resource :dashboard, only: :show

      %w[by_country by_department by_job_title matrix distribution].each do |report|
        get "insights/#{report}", to: "insights##{report}"
      end
    end
  end

  # Anything else that is not an API call is the Angular single-page app.
  root "spa#index"
  get "*path", to: "spa#index", constraints: ->(req) { !req.path.start_with?("/api") && req.format.html? }
end
1