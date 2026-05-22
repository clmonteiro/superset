# Guia de Instalação - Superset POC com PostgreSQL

Documentação completa para subir um Apache Superset local com PostgreSQL, Redis e suporte a upload de CSV.

## 📋 Requisitos

- **Docker Desktop** instalado e rodando (Windows 11 com WSL2)
- ~6GB de RAM disponível
- Portas livres: `8088` (Superset UI), `5433` (PostgreSQL), `6379` (Redis)

Verificar com:
```bash
docker version
docker compose version
```

## 🚀 Início Rápido

### 1. Clonar o repositório
```bash
git clone https://github.com/seu-usuario/superset.git
cd superset
```

### 2. Subir o stack
```bash
docker compose -f docker-compose-standalone.yml up -d
```

Aguarde ~20-30 segundos para os containers inicializarem.

### 3. Instalar driver PostgreSQL
```bash
docker exec -u root superset_app bash -c "apt-get update -qq && apt-get install -y python3-psycopg2 libpq5"
docker exec -u root superset_app bash -c "rm -rf /app/.venv/lib/python3.10/site-packages/psycopg2* && pip install --target /app/.venv/lib/python3.10/site-packages psycopg2-binary"
```

### 4. Inicializar Superset
```bash
docker exec superset_app superset db upgrade
docker exec superset_app superset fab create-admin --username admin --firstname Admin --lastname User --email admin@superset.local --password admin
docker exec superset_app superset init
```

### 5. Acessar a interface
- **URL**: http://localhost:8088
- **Usuário**: `admin`
- **Senha**: `admin`

## 🗄️ Arquitetura

```
superset_app (Flask + UI) ──┐
                             ├─→ superset_postgres (PostgreSQL)
superset_websocket ──────────┤
                             └─→ superset_redis (Cache)
```

| Serviço | Container | Porta (Host) | Porta (Interno) | User/Pass |
|---------|-----------|------------|---------------|-----------|
| Superset | superset_app | 8088 | 8088 | admin/admin |
| PostgreSQL | superset_postgres | 5433 | 5432 | superset/superset |
| Redis | superset_redis | 6379 | 6379 | - |

## 📊 Configurar Banco de Dados para Upload de CSV

### Passo 1: Adicionar conexão PostgreSQL

1. Acesse http://localhost:8088
2. Login com `admin/admin`
3. **Settings** → **Database Connections** → **+ Database**
4. Selecione **PostgreSQL**
5. Preencha:
   ```
   Hostname: postgres
   Port: 5432
   Database name: superset
   Username: superset
   Password: superset
   Display Name: PostgreSQL
   ```

### Passo 2: Habilitar uploads de CSV

Na tela de edição do database:
1. Vá à aba **Advanced**
2. Role até **Security**
3. Marque ☑️ **"Allow file uploads to database"**
4. Clique **"Finish"**

### Passo 3: Fazer upload de CSV

1. Menu superior **+ Data**
2. Clique em **"Upload CSV to database"**
3. Escolha seu arquivo CSV
4. Selecione o banco **PostgreSQL**
5. Dê um nome à tabela
6. **Save**

O Superset criará a tabela automaticamente e você poderá explorar os dados.

## 📈 Criar seu Primeiro Dashboard

1. **Datasets** → selecione o dataset criado pelo upload
2. **Create Chart** → escolha um tipo de visualização
3. Configure métricas, dimensões e filtros
4. **Save** → adicione a um novo Dashboard
5. No dashboard, organize os charts como desejar

## 🛑 Comandos Úteis

### Ver status dos containers
```bash
docker compose -f docker-compose-standalone.yml ps
```

### Ver logs da aplicação
```bash
docker logs superset_app -f
```

### Parar o stack
```bash
docker compose -f docker-compose-standalone.yml down
```

### Parar e limpar tudo (perder dados)
```bash
docker compose -f docker-compose-standalone.yml down -v
```

### Reiniciar Superset
```bash
docker compose -f docker-compose-standalone.yml restart superset
```

### Executar comando no container
```bash
docker exec superset_app <comando>
```

## 🔧 Estrutura de Arquivos

```
superset/
├── docker-compose-standalone.yml  # Orquestração dos containers
├── Dockerfile.superset            # Imagem customizada com psycopg2
├── setup-psycopg2.sh             # Script de inicialização
├── GUIA_INSTALACAO.md            # Este arquivo
└── ... (arquivos do Apache Superset)
```

## 💾 Persistência de Dados

Os dados são armazenados em **Docker volumes**:
- `superset_postgres_data` → banco de dados PostgreSQL
- `superset_redis_data` → cache Redis
- `superset_superset_home` → configurações e uploads do Superset

Os volumes persistem entre `docker compose down/up`. Para limpar tudo:
```bash
docker compose -f docker-compose-standalone.yml down -v
```

## 🔐 Segurança

⚠️ **Importante para produção:**
1. Trocar `SECRET_KEY` em `docker-compose-standalone.yml`
2. Trocar senhas padrão (superset/superset)
3. Configurar HTTPS
4. Restringir acesso à rede

Para POC local, as configurações padrão são aceitáveis.

## 🐛 Troubleshooting

### "Connection failed to database"
- Verificar: `docker compose ps` - todos os containers devem estar `healthy`
- Verificar configuração do banco em **Settings → Database Connections**
- Hostname deve ser `postgres` (nome do serviço Docker), não `localhost`

### "psycopg2 not found"
- Reexecutar o comando de instalação do driver:
```bash
docker exec -u root superset_app bash -c "apt-get update -qq && apt-get install -y python3-psycopg2"
docker exec -u root superset_app bash -c "pip install --target /app/.venv/lib/python3.10/site-packages psycopg2-binary"
```

### "Port already in use"
- Verificar qual processo usa a porta:
  - Windows: `netstat -ano | findstr :8088`
  - Linux/Mac: `lsof -i :8088`
- Mudar porta em `docker-compose-standalone.yml` (seção `ports`)

### Dashboard não carrega
- Limpar cache do navegador (Ctrl+Shift+Delete)
- Reiniciar container: `docker compose restart superset`

## 📚 Próximas Etapas

1. **Explorar exemplos**: Carregar `SUPERSET_LOAD_EXAMPLES=yes` em `docker-compose-standalone.yml`
2. **Alertas e relatórios**: Configurar SMTP em variáveis de ambiente
3. **Row-Level Security**: Limitar acesso de dados por usuário
4. **Integração com BI**: Conectar bancos de produção em vez de usar uploads

## 📖 Documentação Oficial

- [Apache Superset Docs](https://superset.apache.org/docs/)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)

---

**Última atualização**: 2026-05-22  
**Versão Superset**: latest (Apache Superset latest image)  
**Python**: 3.10  
**PostgreSQL**: 15-alpine
