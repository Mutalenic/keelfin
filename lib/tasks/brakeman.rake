namespace :security do
  desc 'Run Brakeman static security analysis'
  task :brakeman do
    require 'brakeman'

    result = Brakeman.run(
      app_path: Rails.root.to_s,
      print_report: true,
      output_formats: [:text],
      exit_on_warn: false
    )

    if result.filtered_warnings.any?
      puts "\n#{result.filtered_warnings.count} security warning(s) found."
      exit 1
    else
      puts "\nNo security warnings found."
    end
  end
end
