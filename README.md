# DVC data 

```bash
cd public
dvc get https://github.com/biaslab/AIDA-data sound
```

# Docker build

```bash
docker build --ssh default -t aida .
```

# Execute docker app

```bash
docker run -p 1234:8000 aida
```
Web Server will start at http://0.0.0.0:1234