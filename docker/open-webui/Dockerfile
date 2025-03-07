ARG WEBUI_TAG
FROM --platform=linux/amd64 ghcr.io/open-webui/open-webui:${WEBUI_TAG}
ARG ASSET_DIR

RUN mkdir /app/backend/open_webui/static/tamu
RUN chmod 755 /app/backend/open_webui/static/tamu

COPY --from=assets static/ /app/backend/open_webui/static/tamu/
RUN chmod 644 /app/backend/open_webui/static/tamu/*