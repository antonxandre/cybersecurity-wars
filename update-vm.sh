#!/usr/bin/env bash
# ==============================================================================
# Cyber Arena - Script de Atualização Direto na VM (GCP)
# ==============================================================================
# Execute este script diretamente no terminal da VM:
# cd ~/app && ./update-vm.sh
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=====================================================${NC}"
echo -e "${CYAN}🔄 Cyber Arena - Atualizando VM de Produção      ${NC}"
echo -e "${CYAN}=====================================================${NC}"

cd ~/app

# Garantir posse dos arquivos
sudo chown -R "$USER:$USER" ~/app

# 1. Atualizar o código do Git
echo -e "\n${BLUE}📥 [1/4] Puxando atualizações do GitHub...${NC}"
git pull origin main || git pull
echo -e "${GREEN}✓ Repositório atualizado.${NC}"

# 2. Descompactar o build do Flutter Web se houver um novo arquivo web.tar.gz
if [ -f "web.tar.gz" ]; then
    echo -e "\n${BLUE}📂 [2/4] Novo build do Flutter Web detectado! Descompactando...${NC}"
    mkdir -p frontend/build
    tar -xzf web.tar.gz -C frontend/build/
    rm -f web.tar.gz
    chmod -R 755 frontend/build/web
    echo -e "${GREEN}✓ Frontend atualizado com sucesso.${NC}"
else
    echo -e "\n${YELLOW}⏭️  [2/4] Nenhum novo web.tar.gz encontrado, mantendo frontend atual.${NC}"
fi

# 3. Rebuild dos containers Docker
echo -e "\n${BLUE}🐳 [3/4] Reconstruindo e reiniciando contêineres...${NC}"
docker compose up -d --build
docker compose exec -T backend npx prisma migrate deploy || true
docker compose restart nginx
echo -e "${GREEN}✓ Contêineres Docker atualizados e saudáveis.${NC}"

# 4. Validar saúde da aplicação
echo -e "\n${BLUE}🔍 [4/4] Verificando saúde da API...${NC}"
sleep 2
if curl -s -f http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API está respondendo 200 OK!${NC}"
    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}🎉 ATUALIZAÇÃO CONCLUÍDA COM SUCESSO NA VM!          ${NC}"
    echo -e "${GREEN}=====================================================${NC}"
else
    echo -e "${YELLOW}⚠️ API ainda está iniciando. Verifique com: docker compose logs backend${NC}"
fi
