FROM node:24 AS installer
COPY . /juice-shop
WORKDIR /juice-shop
RUN npm i -g typescript ts-node
RUN npm install --omit=dev --unsafe-perm
RUN npm dedupe --omit=dev
RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets
RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true

# keep version in sync with package.json
ARG CYCLONEDX_NPM_VERSION='^2.0.0||^3.0.0||^4.0.0'
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
RUN npm run sbom

FROM gcr.io/distroless/nodejs24-debian13
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Graham Vasquez <graham@phlcode.club>" \
  org.opencontainers.image.title="Intergalactic Bazaar" \
  org.opencontainers.image.description="It's legit just Juice Shop lol" \
  org.opencontainers.image.authors="Graham Vasquez <graham@phlcode.club>" \
  org.opencontainers.image.vendor="PHL Code Club" \
  org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.version="19.2.1" \
  org.opencontainers.image.url="https://ctf.phlcode.club" \
  org.opencontainers.image.source="https://github.com/phl-code-club/juice-shop" \
  org.opencontainers.image.revision=$VCS_REF \
  org.opencontainers.image.created=$BUILD_DATE
WORKDIR /juice-shop
COPY --from=installer --chown=65532:0 /juice-shop .
USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]
