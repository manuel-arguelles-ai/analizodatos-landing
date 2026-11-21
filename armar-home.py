#!/usr/bin/env python3
"""IMPORTANTE: el build de Next debe hacerse con BASE_PATH='' (si no, las rutas salen con /nuevo-index y la página queda sin estilos): cd analizodatos-next && BASE_PATH='' npm run build
Regenera artifacts/index-scroll-analizodatos/home-scroll/index.html: toma el export de Next (analizodatos-next/out/index.html)
y le reinyecta el bloque propio del recorrido (home-bloques/sc-embed.*). Úsalo tras `npm run build` en analizodatos-next."""
import os
H=os.path.expanduser("~/clawd")
B=H+"/projects/analizodatos-landing/home-bloques"
new=open(H+"/projects/analizodatos-next/out/index.html").read()
new=new.replace("</head>",open(B+"/sc-embed.style.html").read()+"</head>",1).replace("</body>",open(B+"/sc-embed.script.html").read()+"</body>",1)
open(H+"/artifacts/index-scroll-analizodatos/home-scroll/index.html","w").write(new); print("home regenerada",len(new))
