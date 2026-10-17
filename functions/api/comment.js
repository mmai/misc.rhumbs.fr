// POST /api/comment
//
// Receives the comment form, and opens a pull request adding
// content/<section>/<page>/comments/<timestamp>-<id>.json to the repository.
// Merging the pull request publishes the comment (Cloudflare Pages rebuilds on push).
//
// Environment variables (Pages > Settings > Variables and secrets):
//   GITHUB_TOKEN      (secret) fine-grained token on the repo: Contents + Pull requests read/write
//   GITHUB_REPO       e.g. "mmai/misc.rhumbs.fr"
//   GITHUB_BRANCH     base branch, default "main"
//   TURNSTILE_SECRET  (secret, optional) enables Cloudflare Turnstile verification

const MAX_NAME = 80;
const MAX_URL = 200;
const MAX_MESSAGE = 5000;
// Only page bundles of these sections can receive comments.
const PAGE_PATH_RE = /^(blog|microblog)\/[A-Za-z0-9._:+-]+\/index\.md$/;

export async function onRequestPost({ request, env }) {
  if (!env.GITHUB_TOKEN || !env.GITHUB_REPO) {
    console.error("Missing GITHUB_TOKEN or GITHUB_REPO environment variable");
    return page(500, "Les commentaires ne sont pas configurés sur ce site.");
  }

  let form;
  try {
    form = await request.formData();
  } catch {
    return page(400, "Requête invalide.");
  }

  // Honeypot: hidden field that humans leave empty.
  if (form.get("website_confirm")) {
    return page(200, "Merci ! Votre commentaire sera publié après modération.");
  }

  const pagePath = str(form.get("page"));
  const name = str(form.get("name"));
  const url = str(form.get("url"));
  const message = str(form.get("message"));
  const backUrl = safeBackUrl(str(form.get("back")), request.url);

  if (!PAGE_PATH_RE.test(pagePath) || pagePath.includes("..")) {
    return page(400, "Page inconnue.", backUrl);
  }
  if (!name || name.length > MAX_NAME) {
    return page(400, `Le nom est obligatoire (${MAX_NAME} caractères max).`, backUrl);
  }
  if (!message || message.length > MAX_MESSAGE) {
    return page(400, `Le message est obligatoire (${MAX_MESSAGE} caractères max).`, backUrl);
  }
  if (url && (url.length > MAX_URL || !/^https?:\/\/[^\s]+$/i.test(url))) {
    return page(400, "Le site web doit être une adresse http(s).", backUrl);
  }

  if (env.TURNSTILE_SECRET) {
    const ok = await verifyTurnstile(
      env.TURNSTILE_SECRET,
      str(form.get("cf-turnstile-response")),
      request.headers.get("CF-Connecting-IP"),
    );
    if (!ok) {
      return page(403, "Vérification anti-spam échouée, veuillez réessayer.", backUrl);
    }
  }

  const gh = github(env);
  const base = env.GITHUB_BRANCH || "main";

  // The page must exist on the base branch.
  const pageRes = await gh(`/contents/content/${encodePath(pagePath)}?ref=${base}`);
  if (pageRes.status === 404) {
    console.error(`GitHub 404 for content/${pagePath} on ${env.GITHUB_REPO}@${base}`);
    return page(400, "Page inconnue.", backUrl);
  }
  if (!pageRes.ok) {
    console.error(`GitHub ${pageRes.status} for content/${pagePath}: ${await pageRes.text()}`);
    return page(502, "Erreur lors de l'enregistrement du commentaire.", backUrl);
  }

  const now = new Date();
  const id = crypto.randomUUID().slice(0, 8);
  const stamp = now.toISOString().replace(/[-:]/g, "").replace(/\.\d+Z$/, "Z"); // 20261017T153000Z
  const pageDir = pagePath.replace(/\/index\.md$/, "");
  const filePath = `content/${pageDir}/comments/${stamp}-${id}.json`;
  const branch = `comment/${stamp}-${id}`;

  const comment = { id, date: now.toISOString(), name, url: url || null, message };

  try {
    const ref = await json(gh(`/git/ref/heads/${base}`));
    await json(gh("/git/refs", "POST", { ref: `refs/heads/${branch}`, sha: ref.object.sha }));
    await json(
      gh(`/contents/${encodePath(filePath)}`, "PUT", {
        message: `Comment from ${name} on ${pageDir}`,
        content: base64(JSON.stringify(comment, null, 2) + "\n"),
        branch,
      }),
    );
    await json(
      gh("/pulls", "POST", {
        title: `Comment from ${name} on ${pageDir}`,
        head: branch,
        base,
        body: `**${name}**${url ? ` (${url})` : ""} on \`${pageDir}\`:\n\n${quote(message)}\n\nMerge to publish, close to reject.`,
      }),
    );
  } catch (e) {
    console.error(e);
    return page(502, "Erreur lors de l'enregistrement du commentaire.", backUrl);
  }

  return page(200, "Merci ! Votre commentaire sera publié après modération.", backUrl);
}

function github(env) {
  return (path, method = "GET", body) =>
    fetch(`https://api.github.com/repos/${env.GITHUB_REPO}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "misc.rhumbs.fr-comments",
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
}

async function json(resPromise) {
  const res = await resPromise;
  if (!res.ok) {
    throw new Error(`GitHub API ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

async function verifyTurnstile(secret, token, ip) {
  if (!token) return false;
  const body = new FormData();
  body.append("secret", secret);
  body.append("response", token);
  if (ip) body.append("remoteip", ip);
  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body,
  });
  const data = await res.json();
  return data.success === true;
}

function str(value) {
  return typeof value === "string" ? value.trim() : "";
}

function encodePath(path) {
  return path.split("/").map(encodeURIComponent).join("/");
}

function base64(text) {
  const bytes = new TextEncoder().encode(text);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
}

function quote(text) {
  return text.split("\n").map((l) => `> ${l}`).join("\n");
}

// Only allow redirecting back to a page of this site.
function safeBackUrl(back, requestUrl) {
  try {
    const origin = new URL(requestUrl).origin;
    const url = new URL(back, origin);
    return url.origin === origin ? url.pathname : "/";
  } catch {
    return "/";
  }
}

function escapeHtml(text) {
  return text.replace(/[&<>"']/g, (c) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c],
  );
}

function page(status, text, backUrl = "/") {
  const html = `<!doctype html>
<html lang="fr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Commentaire</title>
<style>body{font-family:system-ui,sans-serif;max-width:600px;margin:4rem auto;padding:0 1rem;line-height:1.5}</style>
</head>
<body><p>${escapeHtml(text)}</p><p><a href="${escapeHtml(backUrl)}#comments">← Retour à la page</a></p></body>
</html>`;
  return new Response(html, { status, headers: { "Content-Type": "text/html; charset=utf-8" } });
}
