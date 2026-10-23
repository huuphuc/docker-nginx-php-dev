# php-dev (nginx + PHP-FPM)

Nginx + PHP-FPM on Ubuntu 22.04, for **local development**.
Docker Hub: [`huuphuc/php-dev`](https://hub.docker.com/r/huuphuc/php-dev) ·
Source: [`huuphuc/docker-nginx-php-dev`](https://github.com/huuphuc/docker-nginx-php-dev)

> **Development only.** Errors are displayed in the browser (`display_errors = On`,
> `error_reporting = E_ALL`) and `memory_limit` is unlimited by default.
> Do not use it for staging or production.

## Tags

Every tag is available for `linux/amd64` and `linux/arm64`. Current PHP version of each tag
(updated automatically on every publish):

<!-- php-versions:start -->
| Tag | PHP |
| --- | --- |
| `8.2` | 8.2.35 |
| `8.3` | 8.3.36 |
| `8.4` | 8.4.27 |
| `8.5`, `latest` | 8.5.12 |
<!-- php-versions:end -->

| Tag | Meaning |
| --- | --- |
| `<php>`, e.g. `8.5` | Newest build of that PHP version. Moves whenever the image is rebuilt. |
| `<php>-v<release>`, e.g. `8.5-v1.2` | A release of this repository. Never overwritten; pin this for reproducible setups. |
| `<php>-<YYYYMMDD>`, e.g. `8.5-20261023` | A rebuild made on that day to pick up PHP/Ubuntu updates. Only another rebuild on the same day replaces it. |
| `latest` | The highest supported PHP version (currently `8.5`). |

The PHP version inside a pinned tag (`-v<release>`, `-<YYYYMMDD>`) is listed in the summary of the
[Publish workflow run](https://github.com/huuphuc/docker-nginx-php-dev/actions/workflows/publish.yml) that built it.
Tags ending in `-v1.0` or `-v1.1` (e.g. `8.4-v1.1`) are from the old build script and are no longer updated.

## Quick start

Mount your project at `/var/www/dev`. Nginx serves **`/var/www/dev/public`** and sends every
request that is not a file to `public/index.php`, so front-controller frameworks (Laravel, Symfony, …)
work out of the box.

```bash
docker run --rm -p 8080:80 -v "$PWD:/var/www/dev" huuphuc/php-dev:8.5
```

Open http://localhost:8080. Without a mount you get a placeholder page showing the PHP version.

With Docker Compose:

```yaml
services:
  php:
    image: huuphuc/php-dev:8.5
    volumes:
      - .:/var/www/dev
    ports:
      - "127.0.0.1:8080:80"
```

Run commands inside the container (the working directory is `/var/www/dev`):

```bash
docker compose exec php composer install
docker compose exec php php -v
```

## What's included

- Nginx 1.18 and PHP-FPM, connected through `/run/php/php-fpm.sock`.
- PHP extensions: `mysql` (mysqli/PDO), `gmp`, `bcmath`, `bz2`, `curl`, `gd`, `intl`, `mbstring`,
  `readline`, `soap`, `xml`, `zip`, `redis`, `imagick`, `opcache`.
- Composer 2, git, curl, unzip, vim.

## Configuration

**PHP settings.** The image's overrides live in `/etc/php/<version>/{fpm,cli}/conf.d/99-custom.ini`
(see [`configs/php.ini`](configs/php.ini)): errors displayed, limits from the environment variables below,
and OPcache enabled. OPcache checks files on every request, so code changes show up without a
restart. For any other setting, mount your own ini file into both directories, for example
`-v ./my.ini:/etc/php/8.5/fpm/conf.d/zz-my.ini`, and restart the container.

**Environment variables.** Common PHP limits can be set per project without an ini file. They apply
to the web server and the CLI. Recreate the container after changing them (`docker compose up -d`).

| Variable | php.ini setting | Default |
| --- | --- | --- |
| `PHP_MEMORY_LIMIT` | `memory_limit` | `-1` (unlimited) |
| `PHP_UPLOAD_MAX_FILESIZE` | `upload_max_filesize` | `100M` |
| `PHP_POST_MAX_SIZE` | `post_max_size` | `100M` |

```yaml
services:
  php:
    image: huuphuc/php-dev:8.5
    environment:
      PHP_MEMORY_LIMIT: 512M
```

Nginx accepts request bodies up to 100M (`client_max_body_size`), so uploads larger than that are
rejected by nginx even if you raise the PHP limits.

**Nginx.** The site config is `/etc/nginx/conf.d/default.conf` (see [`configs/default.conf`](configs/default.conf)).
Mount your own file over it to change it. Uploads are limited to 100M (`client_max_body_size`).

**Logs.** Nginx access and error logs, PHP-FPM logs and PHP errors are written to the container output.
View them with `docker logs <container>` or `docker compose logs php`.

**Processes.** Nginx and PHP-FPM run under supervisord and are restarted automatically if they crash.
To run extra processes, such as a queue worker, add a program file to `/etc/supervisor/conf.d/`.

**File ownership.** PHP-FPM runs as `www-data` (uid 33). `docker exec` runs as `root`, so files it
creates in a bind mount (for example `vendor/` after `composer install`) are owned by root on Linux
hosts. Use `docker compose exec -u www-data php ...`, or fix ownership afterwards, if that matters to you.

**HTTPS** is not configured. Only port 80 is served.

## Building locally

```bash
./build.sh                  # build and test the default version (ARG PHP_VERSION in the Dockerfile, currently 8.5)
./build.sh 8.3              # build and test PHP 8.3
TEST_ONLY=1 ./build.sh 8.3  # re-test the locally built "php-dev" image without rebuilding
```

Tests are [goss](https://github.com/goss-org/goss) checks in [`goss.yaml`](goss.yaml), run with dgoss against a
fresh container. `build.sh` downloads goss into `~/.cache/goss` the first time. Local builds are tagged
`php-dev` and are never pushed.

## Releasing (maintainers)

Images are published to Docker Hub only by GitHub Actions. Pull requests and pushes to `main`
build and test every version on both architectures, but publish nothing.

- **Release:** push a git tag, e.g. `git tag v1.2 && git push origin v1.2`. All versions are
  published as `<php>-v1.2`, `<php>` and `latest`. A release tag that already exists on Docker Hub
  is never overwritten; the run fails instead.
- **Rebuild for PHP/Ubuntu updates:** Actions → **Publish** → **Run workflow**, optionally with a
  comma-separated list of versions (e.g. `8.5`). Publishes `<php>-<YYYYMMDD>` and `<php>`.

Pull requests also lint the Dockerfile with hadolint. Nothing is tagged on Docker Hub unless every selected
version builds, passes `goss.yaml` and has no CRITICAL/HIGH vulnerability with an available fix (Trivy) on both
architectures. Supported versions are listed in [`.github/php-versions.json`](.github/php-versions.json);
`latest` always points at the highest one. `ARG PHP_VERSION` in the [`Dockerfile`](Dockerfile) is only the default for local builds.
Each publish also copies this README to the Docker Hub description and updates the PHP version table above.
