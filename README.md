Welcome to **AIDA** demonstrator.
We advice to build the application via [Docker](https://docs.docker.com/get-docker/).

## Acquiring data 
Please download the dataset that is used by AIDA via [DVC](https://dvc.org/doc/install).
```bash
cd public
dvc get https://github.com/biaslab/AIDA-data sound
```
If you unable to download the dataset, please contact developers of AIDA-app repository.

## Docker build

```bash
docker build --ssh default -t aida .
```

## Execute docker app

```bash
docker run -p 1234:8000 aida
```
Web Server will start at http://0.0.0.0:1234
