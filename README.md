# Proyecto Final DevOps — API de Tareas

API REST de gestión de tareas desplegada con Docker sobre el servidor del curso,
con base de datos PostgreSQL, análisis de seguridad (DevSecOps) y monitoreo.

- **Autor:** Julián David Henao Cataño (estudiante11)
- **Servidor:** 178.128.14.98
- **API publicada:** http://178.128.14.98:8011
- **Repositorio base:** https://github.com/jsansis-utp/devops-final

## Arquitectura

El proyecto levanta dos contenedores en una red privada de Docker:

- **est11_api** — API en Python/Flask (servida con Gunicorn). Es la única puerta
  de entrada: se publica en el puerto `8011` del servidor (puerto interno `5000`).
- **est11_db** — PostgreSQL 16. No se publica hacia afuera; solo es accesible por
  la API a través de la red interna de Docker (puerto `5432`).

```
Internet ──8011──> est11_api ──red interna──> est11_db (5432, no expuesta)
```

La configuración y los secretos viven en el archivo `.env`, que nunca se sube al
repositorio (está en `.gitignore`).

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Información del servicio |
| GET | `/health` | Estado de la API y de la base de datos |
| GET | `/tareas` | Lista las tareas |
| POST | `/tareas` | Crea una tarea `{"titulo": "..."}` |
| PUT | `/tareas/<id>` | Actualiza una tarea |
| DELETE | `/tareas/<id>` | Elimina una tarea |

## Puesta en marcha (comandos usados, en orden)

### 1. Conexión y clonación (Git + Linux)
```bash
ssh estudiante11@178.128.14.98
mkdir -p ~/estudiante11
cd ~/estudiante11
git clone https://github.com/JulianHenao-Web/devops-final.git
cd devops-final
git config user.name "JulianHenao-Web"
git config user.email "julian.henao3@utp.edu.co"
```

### 2. Configuración (variables de entorno)
```bash
cp .env.example .env
# Ajustar en .env: ESTUDIANTE=estudiante11, API_PORT=8011,
# POSTGRES_PASSWORD=<clave fuerte>, DB_PORT=5432
```

### 3. Despliegue con Docker
```bash
docker compose up -d --build
docker compose ps
curl http://localhost:8011/health
```

### 4. Prueba del CRUD
```bash
curl -X POST http://localhost:8011/tareas \
  -H "Content-Type: application/json" -d '{"titulo":"Primera tarea"}'
curl http://localhost:8011/tareas
```

### 5. Seguridad y monitoreo
```bash
chmod +x seguridad.sh
./seguridad.sh              # Gitleaks, Semgrep, Syft, Trivy, Hadolint -> reportes/
./seguridad.sh monitorear  # Monitoreo -> monitoreo.log
```

## DevSecOps — `seguridad.sh`

El script ejecuta cinco herramientas de seguridad y guarda cada resultado en la
carpeta `reportes/`:

| Herramienta | Qué revisa | Reporte |
|---|---|---|
| Gitleaks | Secretos filtrados en el repositorio | `gitleaks.json` |
| Semgrep | Análisis estático del código (SAST) | `semgrep.json` |
| Syft | Inventario de dependencias (SBOM) de la imagen | `sbom.json` |
| Trivy | Vulnerabilidades de la imagen | `trivy.txt` |
| Hadolint | Buenas prácticas del `Dockerfile` | `hadolint.txt` |

## Monitoreo — función `monitorear`

Dentro del mismo `seguridad.sh`, la función `monitorear`:

1. Verifica si la API responde en `/health`.
2. Muestra el estado de los contenedores (`docker compose ps`).
3. Muestra los últimos registros de log.
4. Deja constancia del resultado, con fecha, en `monitoreo.log`.

## Notas de servidor compartido

- El `docker-compose.yml` empieza con `name: estudiante11` y nombra los
  contenedores `est11_db` y `est11_api`, para no interferir con los despliegues
  de otros estudiantes.
- La base de datos **no se publica** (el servicio `db` no tiene sección `ports`);
  solo la API es accesible desde fuera.
- El archivo `.env` con las credenciales **nunca** se sube al repositorio.
