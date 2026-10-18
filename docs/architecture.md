# Architecture

## Github

Code and content on Github, with a 'webmentions' workflow enabled (see ./github/workflows/webmentions.yml) which fetch webmentions from webmention.io every 6 hours and update content.

`WEBMENTIONSIO_API_TOKEN` github repository secret set on https://github.com/mmai/misc.rhumbs.fr/settings/secrets/actions.

[Github actions history](https://github.com/mmai/misc.rhumbs.fr/actions)

## Cloudflare

Website hosted on [Cloudflare pages](https://dash.cloudflare.com/0bef16bad1cae92c971c00649ec8b0d0/pages/view/misc-rhumbs-fr) (free), linked to Github repo, rebuilds on each push

Configuration:

Build

- Git repository: mmai/misc.rhumbs.fr
- Build configuration:
  - Build command:zola build
  - Build output:public
  - Root directory:
  - Build comments:Enabled
- Build cache: Disabled
- Branch control
  - Production branch: main
  - Automatic deployments: Enabled
  - (edit -> preview branch: None)
- Build watch paths
  - Include paths: \*
- Build system version: Version 3
- Deploy Hooks: No deploy hooks defined

Variables and secrets

| Type | Name             | Value                                                                                 |
| ---- | ---------------- | ------------------------------------------------------------------------------------- |
| Text | ZOLA_VERSION     | 0.23.6                                                                                |
| Text | GITHUB_REPO      | mmai/misc.rhumbs.fr                                                                   |
| Text | GITHUB_TOKEN     | (from github > profile > settings > credentials > fine grained personal access token) |
| Text | TURNSTILE_SECRET | (from Cloudflare Turnstile widgets)                                                   |

Runtime

- Placement: Default
- Compatibility date: 2025-05-10
- Compatibility flags:
- Fail open/closed: Fail open
