FROM julia

COPY . .

RUN --mount=type=ssh julia --project -e 'import Pkg; Pkg.instantiate()'

CMD [ "julia", "--project", "main.jl" ]