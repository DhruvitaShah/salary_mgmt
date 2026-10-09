# Serves the compiled Angular app (copied into public/ at build time) for every
# non-API route, so deep links like /employees/42 work after a page refresh.
class SpaController < ActionController::API
  def index
    index_file = Rails.public_path.join("index.html")
    if index_file.exist?
      send_file index_file, type: "text/html", disposition: "inline"
    else
      render plain: "ACME Salary API is running. Build the Angular app (see README) to serve the UI from here.", status: :ok
    end
  end
end
