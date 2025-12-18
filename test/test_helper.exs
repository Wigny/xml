Code.prepend_path("_build/#{Mix.env()}/lib/git_snapshot/ebin")
Application.ensure_all_started(:git_snapshot)
ExUnit.start()
