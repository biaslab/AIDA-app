FROM julia

COPY . .

RUN julia --project -e 'import Pkg; Pkg.instantiate()'

CMD [ "julia", "--project", "main.jl" ]