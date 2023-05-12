FROM python:3.9-slim as base

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

FROM base AS python-deps

# install apps dependencies
RUN apt update && apt install -y --no-install-recommends \
    git \
    curl \
    build-essential=12.9 \
    && rm -rf /var/lib/apt/lists/*

# install python dependencies
COPY Makefile Pipfile Pipfile.lock ./
RUN python3.9 -m pip install -U pip==23.0.1 setuptools==67.6.0 pipenv==2023.2.18
RUN make deploy

FROM base AS runtime

RUN useradd --create-home bpyuser
WORKDIR /home/bpyuser
USER bpyuser

# create data directory
RUN mkdir /home/bpyuser/.data

VOLUME /home/bpyuser/.data

# copy the source code in last, so that it doesn't
# repeat the previous steps for each change

COPY Makefile main.py ./
COPY app/ app/
COPY migrations/ migrations/
COPY scripts/ scripts/

COPY --from=python-deps /.venv /.venv
ENV PATH="${PATH}:/.venv/bin"

# start bancho.py
ENTRYPOINT [ "/bin/bash", "-c" ]
CMD ["make run-prod"]
