#!/bin/bash
# Reconstruye el sitio completo de analizodatos.com (estático) y lo despliega a Cloudflare Pages (proyecto analizodatos-landing).
# Fuentes: home viva con el recorrido (artifacts/index-scroll-analizodatos/home-scroll), build Next (analizodatos-next/out), recorrido de las 9 capas,
# blog, 6M-IA, webinar OpenClaw+Codex, tier-list, workflow, consigue-empleo-remoto. Credenciales: ~/.config/cloudflare (nunca se imprimen).
#   bash armar-sitio.sh            # arma y despliega
#   bash armar-sitio.sh --solo-armar
set -euo pipefail
C=~/clawd; S=/tmp/ad-site-$(date +%Y%m%d-%H%M%S)
# cada build pesa ~117 MB: conserva solo el último (llenó el disco el 14-oct-2026)
{ ls -dt /tmp/ad-site-* 2>/dev/null || true; } | tail -n +2 | while read -r d; do rm -rf "$d"; done
mkdir -p "$S"
rsync -a --exclude index.txt $C/projects/analizodatos-next/out/ "$S"/
cp $C/artifacts/index-scroll-analizodatos/home-scroll/index.html "$S/index.html"
mkdir -p "$S/assets"; rsync -a $C/projects/analizodatos-landing/assets/ "$S/assets/"; cp "$S/assets/manuel-photo.jpg" "$S/manu.jpg"
# Gemelo web: widget en la home + página /agendar (la API vive en gemelo-api.analizodatos.com)
mkdir -p "$S/assets/gemelo" "$S/agendar" "$S/privacidad" "$S/yo"; cp $C/projects/analizodatos-landing/gemelo/yo/index.html "$S/yo/index.html"; cp $C/projects/analizodatos-landing/gemelo/privacidad/index.html "$S/privacidad/index.html"; cp $C/projects/analizodatos-landing/gemelo/{widget.js,config.js} "$S/assets/gemelo/"; cp $C/projects/analizodatos-landing/gemelo/agendar/index.html "$S/agendar/index.html"
python3 - "$S/index.html" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); tag='<script src="/assets/gemelo/config.js"></script><script src="/assets/gemelo/widget.js" defer></script>'
if "gemelo/widget.js" not in s: s=s.replace("</body>", tag+"</body>",1); open(p,"w").write(s)
PY
for pair in "metodo-sc:pieza-final-metodo-sc" "metodo-sc-embed:pieza-final-metodo-sc-embed" "scrolling:pieza-scrolling"; do d=${pair%%:*}; s=${pair##*:}; mkdir -p "$S/$d"; rsync -a --exclude .htaccess $C/artifacts/scrollytelling-recorrido/$s/ "$S/$d/"; done
# piloto: fondos del recorrido hechos con HyperFrames, en ruta aparte y sin indexar (comparar con /scrolling/)
mkdir -p "$S/scrolling-hf"; rsync -a --exclude .htaccess $C/artifacts/scrollytelling-recorrido/pieza-scrolling-hf/ "$S/scrolling-hf/"
mkdir -p "$S/scrolling-an"; rsync -a --exclude .htaccess $C/artifacts/scrollytelling-recorrido/pieza-scrolling-an/ "$S/scrolling-an/"
mkdir -p "$S/scrolling-flow-mov"; rsync -a --exclude .htaccess $C/artifacts/scrollytelling-recorrido/pieza-scrolling-flow-mov/ "$S/scrolling-flow-mov/"
[ -d $C/artifacts/scrollytelling-recorrido/pieza-scrolling-flow-fijo ] && { mkdir -p "$S/scrolling-flow"; rsync -a --exclude .htaccess $C/artifacts/scrollytelling-recorrido/pieza-scrolling-flow-fijo/ "$S/scrolling-flow/"; }
mkdir -p "$S/blog"; rsync -a $C/projects/blog-analizodatos/out/ "$S/blog/"
mkdir -p "$S/6M-IA"; cp $C/projects/infografias-linkedin/research/6m-ia/web/framework.html "$S/6M-IA/index.html"
mkdir -p "$S/webinar-openclaw-codex" "$S/webinar-openclaw-codex-slides"
cp $C/taller-openclaw-codex-web/index.html $C/taller-openclaw-codex-web/favicon.png "$S/webinar-openclaw-codex/"
cp $C/taller-openclaw-codex-web/deck-v2.html "$S/webinar-openclaw-codex-slides/index.html"
for d in webinar-openclaw-codex webinar-openclaw-codex-slides; do cp $C/taller-openclaw-codex-web/qr-linkedin-tinta.png "$S/$d/qr-linkedin.png"; done
mkdir -p "$S/consigue-empleo-remoto" "$S/workflow" "$S/tier-list-ai-ecosystem" "$S/fonts" "$S/brand"
cp $C/projects/consigue-empleo-remoto/index.html "$S/consigue-empleo-remoto/"; cp $C/projects/workflow-page/index.html "$S/workflow/"
cp $C/projects/infografias-linkedin/infografias/tier-list-ia/index.html "$S/tier-list-ai-ecosystem/"
rsync -a $C/projects/infografias-linkedin/fonts/ "$S/fonts/"; cp $C/projects/infografias-linkedin/brand/manu-linkedin.jpg "$S/brand/"
mkdir -p "$S/onboarding-claude"; rsync -a --exclude api --exclude data --exclude '*.php' --exclude groq.key $C/../Projects/claudecode-onboarding/out/ "$S/onboarding-claude/"
# calculadora de sueldos tech (roles) — fuente única en ~/calculadora-sueldos
mkdir -p "$S/calculadora-sueldos-tech"; rsync -a --exclude '*.md' ~/calculadora-sueldos/ "$S/calculadora-sueldos-tech/"
# DE Challenges Hub (catálogo estático; sin api/ ni groq.key: el foquito cae al fallback de links)
mkdir -p "$S/data-challenges-hub/catalog"; D=$C/proyectos/databricks-challenges-hub/deploy; cp $D/index.html $D/glossary.json "$S/data-challenges-hub/"; cp $D/catalog/items.json "$S/data-challenges-hub/catalog/"
# Portafolio de soluciones agénticas (repos públicos, búsqueda híbrida en el navegador, ES/EN; fuente: projects/portafolio-agentico: build/proyectos.py + build/embed.mjs + build/imgs.sh)
mkdir -p "$S/portafolio"; rsync -a --exclude "*.png" $C/projects/portafolio-agentico/web/ "$S/portafolio/"
# Ingeniería de datos multicloud (web estática: diseñador + catálogo; publicada con index el 2026-11-10)
mkdir -p "$S/ingenieria-de-datos-multicloud"; cp $C/projects/ingenieria-datos-multicloud/web/index.html "$S/ingenieria-de-datos-multicloud/index.html"
mkdir -p "$S/ingenieria-de-datos-multicloud/assets"; cp $C/projects/ingenieria-datos-multicloud/web/assets/*.jpg "$S/ingenieria-de-datos-multicloud/assets/"
mkdir -p "$S/ingenieria-de-datos-multicloud-equivalencias"; cp $C/projects/ingenieria-datos-multicloud/web/equivalencias.html "$S/ingenieria-de-datos-multicloud-equivalencias/index.html"
# Generador de URL de búsquedas de empleo en LinkedIn (fuente: projects/linkedin-filtros/web)
mkdir -p "$S/linkedin-filtros"; cp $C/projects/linkedin-filtros/web/index.html "$S/linkedin-filtros/index.html"
# Quitar fondo de imágenes (client-side, @imgly/background-removal; fuente: projects/remove-background-web; noindex)
mkdir -p "$S/remove-background"; cp $C/projects/remove-background-web/index.html "$S/remove-background/index.html"
mkdir -p "$S/servicios/vps"; cp $C/projects/analizodatos-landing/servicios/vps/index.html "$S/servicios/vps/index.html"
mkdir -p "$S/agente-de-ventas"; cp $C/proyectos/vende-ia/docs/stack.html "$S/agente-de-ventas/index.html"; cp $C/proyectos/vende-ia/docs/manu-presnap-orange.mp4 "$S/agente-de-ventas/"
printf '/vende-ia https://vende-ai.analizodatos.com/vende-ia 302\n/vende-ia/ https://vende-ai.analizodatos.com/vende-ia 302\n/index-scroll / 301\n/metodo-sc-fix /metodo-sc 301\n' > "$S/_redirects"
printf '/*/d/*\n  Cache-Control: public, max-age=31536000, immutable\n/scrolling-hf/*\n  X-Robots-Tag: noindex\n/scrolling-an/*\n  X-Robots-Tag: noindex\n/scrolling-flow/*\n  X-Robots-Tag: noindex\n/scrolling-flow-mov/*\n  X-Robots-Tag: noindex\n/servicios/*\n  X-Robots-Tag: noindex\n' > "$S/_headers"
printf '/remove-background/*\n  X-Robots-Tag: noindex\n' >> "$S/_headers"
# /chack: informe SLA Aranda (Fabric/Databricks) con clave (Pages Function) + agente OpenClaw VPS; fuente en projects/aranda-sla-fabric-databricks/chack
mkdir -p "$S/chack"; rsync -a $C/projects/aranda-sla-fabric-databricks/chack/public/ "$S/chack/"
mkdir -p $C/projects/analizodatos-landing/functions/chack; rsync -a --delete $C/projects/aranda-sla-fabric-databricks/chack/functions/chack/ $C/projects/analizodatos-landing/functions/chack/
mkdir -p $C/projects/analizodatos-landing/functions/sla-demo; rsync -a --delete $C/projects/aranda-sla-fabric-databricks/chack/functions/sla-demo/ $C/projects/analizodatos-landing/functions/sla-demo/
printf '/chack/*\n  X-Robots-Tag: noindex, nofollow\n  Cache-Control: private, no-store\n' >> "$S/_headers"
# /turgalium: material del curso Caja Trujillo (4 diagramas + FAQ + asistente OpenClaw VPS) con clave (Pages Function); fuente en projects/turgalium-web
(cd $C/projects/turgalium-web && python3 construir.py >/dev/null) || echo "AVISO: turgalium-web/construir.py fallo (depende de un scratchpad que ya no existe); se usa public/ tal cual" >&2
mkdir -p "$S/turgalium"; rsync -a $C/projects/turgalium-web/public/ "$S/turgalium/"
mkdir -p $C/projects/analizodatos-landing/functions/turgalium; rsync -a --delete $C/projects/turgalium-web/functions/turgalium/ $C/projects/analizodatos-landing/functions/turgalium/
printf '/turgalium/*\n  X-Robots-Tag: noindex, nofollow\n  Cache-Control: private, no-store\n' >> "$S/_headers"
# /presupuesto-familiar: gastos del hogar (Manuel y Magenta). Puerta con clave + proxy al contenedor del VPS (cuentas-origen); fuente en projects/cuentas-de-la-casa
mkdir -p $C/projects/analizodatos-landing/functions/presupuesto-familiar; rsync -a --delete $C/projects/cuentas-de-la-casa/pages/functions/presupuesto-familiar/ $C/projects/analizodatos-landing/functions/presupuesto-familiar/
printf '/presupuesto-familiar/*\n  X-Robots-Tag: noindex, nofollow\n  Cache-Control: private, no-store\n' >> "$S/_headers"
# Taller Portafolio de datos (19-nov-2026): láminas con clave (Pages Function) + web de registro y preguntas en vivo (D1, binding TALLER_DB); fuente en projects/taller-portafolio-datos
T=$C/projects/taller-portafolio-datos
mkdir -p "$S/taller-portafolio-datos" "$S/taller-portafolio-datos-e2e"
rsync -a $T/deck/index.html $T/deck/deck.css $T/deck/deck.js $T/deck/assets "$S/taller-portafolio-datos/"
rsync -a $T/web/e2e/ "$S/taller-portafolio-datos-e2e/"
mkdir -p "$S/taller-portafolio-datos/guion"; cp $T/web/guion/index.html "$S/taller-portafolio-datos/guion/index.html"  # guion del presentador, tras la misma clave
python3 - "$S/taller-portafolio-datos/index.html" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read(); a='<button id="bMarcas"'
if "bGuion" not in s and a in s: open(p,"w").write(s.replace(a, '<button id="bGuion" type="button" onclick="window.open(\'guion/\',\'_blank\')">Guion</button>\n  '+a,1))
PY
for d in taller-portafolio-datos taller-portafolio-datos-e2e; do mkdir -p $C/projects/analizodatos-landing/functions/$d; rsync -a --delete $T/web/functions/$d/ $C/projects/analizodatos-landing/functions/$d/; done
cp $T/web/functions/_lib/taller_acceso.js $C/projects/analizodatos-landing/functions/_lib/
printf '/taller-portafolio-datos/*\n  X-Robots-Tag: noindex, nofollow\n  Cache-Control: private, no-store\n/taller-portafolio-datos-e2e/*\n  X-Robots-Tag: noindex, nofollow\n' >> "$S/_headers"
echo "armado en $S ($(du -sh "$S" | cut -f1), $(find "$S" -type f | wc -l) archivos)"
[ "${1:-}" = "--solo-armar" ] && exit 0
export CLOUDFLARE_ACCOUNT_ID=f34c339046f4d904e327032ba505c82e CLOUDFLARE_API_TOKEN=$(cat ~/.config/cloudflare/pages_deploy_token)  # token con permiso minimo: Cloudflare Pages Edit (20-oct-2026); ya no usa la clave global
# Medición propia (cookies propias _ad_vid/_ad_ses/_ad_own; /yo marca los navegadores de Manu): t.js en todas las páginas HTML + Función /t/e (functions/ se despliega junto al sitio)
cp $C/projects/analizodatos-landing/gemelo/t.js "$S/assets/gemelo/t.js"
python3 - "$S" <<'PY'
import sys,pathlib
tag='<script src="/assets/gemelo/t.js" defer></script>'
n=0
for p in pathlib.Path(sys.argv[1]).rglob("*.html"):
    if "/_next/" in str(p) or "/admin/" in str(p): continue
    s=p.read_text(errors="ignore")
    if "gemelo/t.js" in s or "</body>" not in s: continue
    p.write_text(s.replace("</body>",tag+"</body>",1)); n+=1
print("t.js inyectado en",n,"páginas")
PY
cd ~/clawd/projects/analizodatos-landing && wrangler pages deploy "$S" --project-name analizodatos-landing --branch main --commit-dirty=true 2>&1 | tail -3
