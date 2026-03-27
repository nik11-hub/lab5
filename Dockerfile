# ETAP 1
FROM alpine:latest AS builder

# Definiujemy argument wersji
ARG VERSION

# Instalujemy narzędzia potrzebne do edycji tekstu
RUN apk add --no-cache gettext

# Kopiujemy nasz szablon
COPY index.html /tmp/index.html

# Tworzymy skrypt, który wygeneruje końcowy HTML przy starcie kontenera
# Musimy to zrobić dynamicznie, bo IP i Hostname zmieniają się przy każdym uruchomieniu
RUN echo '#!/bin/sh' > /usr/local/bin/entrypoint.sh && \
    echo 'IP=$(hostname -i)' >> /usr/local/bin/entrypoint.sh && \
    echo 'HOSTNAME=$(hostname)' >> /usr/local/bin/entrypoint.sh && \
    echo "sed -e \"s/SERVER_IP/\$IP/g\" -e \"s/SERVER_HOSTNAME/\$HOSTNAME/g\" -e \"s/APP_VERSION/$VERSION/g\" /tmp/index.html > /usr/share/nginx/html/index.html" >> /usr/local/bin/entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# ETAP 2
FROM nginx:alpine

# Kopiujemy szablon strony i skrypt startowy z etapu builder
COPY --from=builder /tmp/index.html /tmp/index.html
COPY --from=builder /usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 80

# Ustawiamy HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

# Uruchamiamy nasz skrypt zamiast domyślnego serwera nginx
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]    