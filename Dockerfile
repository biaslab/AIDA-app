FROM julia

COPY Manifest.toml .
COPY Project.toml .

RUN --mount=type=ssh julia --project -e 'import Pkg; Pkg.instantiate()'

COPY . .

# ports
EXPOSE 8000
EXPOSE 80

# set up app environment
ENV GENIE_ENV "dev"
ENV HOST "0.0.0.0"
ENV PORT "8000"
ENV WSPORT "8000"
ENV EARLYBIND "true"

# run app
CMD [ "julia", "--project", "main.jl" ]