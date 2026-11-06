FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
LABEL org.opencontainers.image.source="https://github.com/andTruth/lean-eval-hessian-harness-challenge"
USER root

RUN apt-get update && apt-get install -y --no-install-recommends git nodejs npm jq ripgrep tmux libgmp-dev \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g --no-audit --no-fund @openai/codex@0.166.0

RUN mkdir -p /workspace/problem /opt/elan /opt/lean-packages \
    && chown -R vscode:vscode /workspace /opt/elan /opt/lean-packages \
    && git config --system --add safe.directory '*'
ENV ELAN_HOME="/opt/elan" PATH="/opt/elan/bin:${PATH}"
USER vscode
RUN curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
    | sh -s -- -y --default-toolchain none
RUN mkdir -p /home/vscode/.codex
WORKDIR /workspace/problem

COPY --chown=vscode:vscode problem/lean-toolchain problem/lakefile.toml ./
RUN lake exe cache get && elan default leanprover/lean4:v4.35.0 \
    && chmod -R a+rwX /opt/elan /opt/lean-packages
ENV MATHLIB_NO_CACHE_ON_UPDATE=1
COPY --chown=vscode:vscode problem/*.lean problem/.gitignore ./
RUN lake build Problem && mkdir -p scratch \
    && git init -q -b main \
    && git config user.name Agent && git config user.email agent@localhost \
    && git add . && git commit -qm "Initial proof workspace"
COPY --chown=vscode:vscode config.toml /home/vscode/.codex/config.toml
COPY --chown=vscode:vscode run.sh prompt.txt prompt-follup.txt README.md .gitignore /workspace/
COPY --chown=vscode:vscode third_party/ /workspace/third_party/
WORKDIR /workspace
CMD ["bash"]
