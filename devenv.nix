{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.act pkgs.zola pkgs.just pkgs.uglify-js pkgs.jaq pkgs.wrangler ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  processes.zola-dev.exec = "zola serve";
  processes.wrangler.exec = "zola build -u http://localhost:8788 && wrangler pages dev public";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
  '';

  enterShell = ''
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
