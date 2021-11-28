FROM julia

COPY Manifest.toml .
COPY Project.toml .

RUN --mount=type=ssh julia --project -e 'import Pkg; Pkg.instantiate()'

COPY . .

CMD [ "julia", "--project", "main.jl" ]