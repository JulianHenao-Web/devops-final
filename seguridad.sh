#!/bin/bash
# seguridad.sh - DevSecOps y monitoreo del Proyecto Final DevOps
# Uso:
#   ./seguridad.sh             -> analisis de seguridad + un monitoreo
#   ./seguridad.sh monitorear  -> solo el monitoreo

IMAGEN="est11_api:1.0"
REPORTES="reportes"
URL_HEALTH="http://localhost:8011/health"
LOG_MONITOREO="monitoreo.log"

mkdir -p "$REPORTES"

analizar_seguridad() {
    echo "===== [1/5] Gitleaks: busqueda de secretos ====="
    gitleaks detect --source=. -v --report-path="$REPORTES/gitleaks.json" \
        || echo "[!] Gitleaks reporto hallazgos"

    echo "===== [2/5] Semgrep: analisis estatico (SAST) ====="
    PYTHONWARNINGS="ignore" semgrep scan --config=p/owasp-top-ten \
        --json -o "$REPORTES/semgrep.json" \
        || echo "[!] Semgrep reporto hallazgos"

    echo "===== [3/5] Syft: inventario SBOM de la imagen ====="
    syft "$IMAGEN" -o cyclonedx-json > "$REPORTES/sbom.json" \
        || echo "[!] Error ejecutando Syft"

    echo "===== [4/5] Trivy: vulnerabilidades de la imagen ====="
    trivy image --severity HIGH,CRITICAL "$IMAGEN" > "$REPORTES/trivy.txt" 2>&1 \
        || echo "[!] Trivy reporto vulnerabilidades"

    echo "===== [5/5] Hadolint: buenas practicas del Dockerfile ====="
    hadolint Dockerfile > "$REPORTES/hadolint.txt" 2>&1 \
        || echo "[!] Hadolint reporto advertencias"

    echo "===== Analisis finalizado. Reportes en $REPORTES/ ====="
}

monitorear() {
    local fecha
    fecha=$(date "+%Y-%m-%d %H:%M:%S")
    {
        echo "===================================================="
        echo "[$fecha] MONITOREO DEL SERVICIO"
        echo "---- 1. Estado de la API (/health) ----"
        if curl -s -f "$URL_HEALTH" > /dev/null; then
            echo "API OK -> $(curl -s "$URL_HEALTH")"
        else
            echo "API SIN RESPUESTA en $URL_HEALTH"
        fi
        echo "---- 2. Estado de los contenedores ----"
        docker compose ps
        echo "---- 3. Ultimos logs (10 lineas) ----"
        docker compose logs --tail=10
        echo ""
    } | tee -a "$LOG_MONITOREO"
}

case "$1" in
    monitorear)
        monitorear
        ;;
    *)
        analizar_seguridad
        monitorear
        ;;
esac
