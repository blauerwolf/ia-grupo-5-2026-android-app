#!/bin/bash

# Script helper para correr el servidor de inferencia utilizando el entorno pipenv correcto

# Colores para la consola
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}Iniciando Servidor de Inferencia para Lenguaje de Señas...${NC}"
echo -e "Puerto por defecto: ${BLUE}5005${NC}"
echo -e "Entorno virtual: ${BLUE}ia-utn-frlp-2026-grupo-5/Pipfile${NC}"
echo -e "${BLUE}============================================================${NC}"

# Comando que ejecuta Pipenv apuntando al Pipfile del grupo-5 usando el python3.11 de homebrew
PIPENV_PIPFILE=../ia-utn-frlp-2026-grupo-5/Pipfile /opt/homebrew/bin/python3.11 -m pipenv run python server.py 5005
