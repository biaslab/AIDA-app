# DVC data 

```bash
dvc get https://github.com/biaslab/AIDA-data sound
```

# Docker build

```
docker build --ssh default -t aida .
```

# Execute docker app

```
docker run -p 1234:8000 aida
```
