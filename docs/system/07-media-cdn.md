# 07 — Mídia e CDN

**Normativo.** Primer: CDN push/pull. Focux: **Cloudinary** como CDN de mídia.

## Regras

1. **Upload via allowlist + sniff + Cloudinary** — não aceitar URL arbitrária com fetch server-side (SSRF).
2. **`uploadFromUrl` só CDN curada** (seed/biblioteca). Chat/feed `midiaUrl` = store-only no BE.
3. **MoveKit:** URLs em seed; enriquecer texto sem wipe de URL; nunca regenerar seed cru que apague Cloudinary.
4. **Imagens/vídeos de exercício** servidos pelo CDN; app não embute binários grandes no APK/IPA.
5. **Landing/og:image:** cuidado com Host header; não cache-confundir entre tenants.

## Por quê

CDN reduz latência e origem. Fetch de URL do usuário = SSRF. Seed destrutivo já quebrou mídia em produção.

## Onde no código

- Upload: `UploadController`, serviços Cloudinary
- Seed: `CuratedSeedV2Service`, `tool/movekit/*`
- App: `MediaUploadService`, players check-in S8

## Gate

- [ ] Nenhum endpoint novo faz HTTP GET em URL do client sem allowlist.
- [ ] Patch de biblioteca preserva `gifUrl`/`videoUrl`.
- [ ] Release não depende de cleartext para mídia.
