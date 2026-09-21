# 🐳 LigeroSmart - Imagens Docker

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-Custom-blue.svg?style=for-the-badge)](LICENSE)

Conjunto de imagens Docker para o **LigeroSmart**, plataforma completa de Service Desk e ITSM com alta disponibilidade, escalabilidade e recursos corporativos avançados.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Arquitetura](#-arquitetura)
- [Imagens Disponíveis](#-imagens-disponíveis)
- [Recursos Principais](#-recursos-principais)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Sistema de Backup](#-sistema-de-backup)
- [Início Rápido](#-início-rápido)
- [Portas e Volumes](#-portas-e-volumes)
- [Bancos de Dados](#-bancos-de-dados)
- [Integrações](#-integrações)
- [Documentação](#-documentação)

---

## 🎯 Visão Geral

Este repositório contém as imagens Docker oficiais do LigeroSmart, projetadas para oferecer:

- ✅ **Instalação Automatizada** - Deploy simplificado com configuração inicial automatizada
- ✅ **Alta Disponibilidade** - Múltiplas variantes de servidores web (Apache2, Nginx)
- ✅ **Escalabilidade Horizontal** - Separação de serviços (web, scheduler, sshd)
- ✅ **Backup Inteligente** - Sistema completo de backup e sincronização com S3
- ✅ **Monitoramento Integrado** - Healthchecks e integração com Zabbix
- ✅ **Suporte Multi-Database** - MariaDB (recomendado), MySQL, PostgreSQL e Oracle
- ✅ **Desenvolvimento Facilitado** - Imagem dedicada para ambiente de desenvolvimento

---

## 🏗️ Arquitetura

O LigeroSmart utiliza uma arquitetura modular baseada em containers:

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌────────┐  ┌────────┐  ┌────────┐
   │ Nginx  │  │ Nginx  │  │Apache2 │  ◄── Web Servers
   └───┬────┘  └───┬────┘  └───┬────┘
       │           │           │
       └───────────┼───────────┘
                   │
         ┌─────────┼─────────┐
         ▼         ▼         ▼
    ┌────────┐ ┌──────┐ ┌─────────────┐
    │Database│ │Redis │ │Elasticsearch│  ◄── Data Layer
    └────────┘ └──────┘ └─────────────┘
         ▲
         │
    ┌─────────┐
    │Scheduler│  ◄── Background Jobs
    └─────────┘
         │
    ┌─────────┐
    │ Backup  │  ◄── Backup & External Sync
    └─────────┘
```

---

## 📦 Imagens Disponíveis

### **Base** (`ligero/ligerosmart:base`)
Imagem base com todas as dependências do LigeroSmart pré-instaladas.

**Características:**
- 🐧 Ubuntu 20.04 LTS
- 🐪 Perl 5 com módulos CPAN otimizados
- 📦 Dependências para MariaDB, MySQL, PostgreSQL
- 🔧 Ferramentas: git, curl, vim, AWS CLI
- 📧 Sistema de e-mail via gosendmail
**Inclui:**
- Cache::Memcached::Fast e Redis
- Suporte a Elasticsearch 7.x
- Módulos Perl para LDAP, IMAP, SASL
- Bibliotecas de template e processamento XML/YAML

---

### **Apache2** (`ligero/ligerosmart:apache2`)
Servidor web Apache com mod_perl para máxima performance.

**Características:**
- 🌐 Apache 2.4 + mod_perl2
- ⚡ Otimizado para requisições síncronas
- 🏥 Healthcheck integrado
- 📊 Logs estruturados (stdout/stderr)

**Portas:** `80`

**Variáveis principais:**
```bash
START_WEBSERVER=1
START_SCHEDULER=1
```

---

### **Nginx** (`ligero/ligerosmart:nginx`)
Servidor web Nginx com Starman (PSGI/Plack) para alta concorrência.

**Características:**
- 🚀 Nginx 1.18.x + Starman
- ⚙️ Suporte a múltiplos workers
- 🐛 Devel::NYTProf para profiling
- 🔥 Performance superior para requisições assíncronas

**Portas:** `80`

**Variáveis principais:**
```bash
START_WEBSERVER=1
START_SCHEDULER=1
STARMAN_WORKERS=3
PLACK_ENV=deployment
DEBUG_MODE=0
```

---

### **Nginx-Dev** (`ligero/ligerosmart:nginx-dev`)
Variante do Nginx otimizada para desenvolvimento.

**Características:**
- 🛠️ Ferramentas de debug incluídas
- 📧 Integração com MailCatcher
- 🔍 Configurações de Elasticsearch para debug
- 🔄 Hot-reload para desenvolvimento

---

### **Scheduler** (`ligero/ligerosmart:scheduler`)
Container dedicado para execução de tarefas agendadas.

**Características:**
- ⏰ Cron integrado
- 🔄 Processamento de filas
- 📅 Jobs recorrentes (tickets, notificações, limpeza)
- 📈 Monitoramento de tarefas

**Variáveis principais:**
```bash
START_WEBSERVER=0
START_SCHEDULER=1
```

**Ideal para:** Ambientes de produção com separação de responsabilidades.

---

### **SSHD** (`ligero/ligerosmart:sshd`)
Container com acesso SSH para administração e troubleshooting.

**Características:**
- 🔐 Acesso SSH seguro
- 🛠️ Ferramentas de diagnóstico (htop, nmap, mtr, ncdu)
- 🗄️ MySQLTuner incluído
- 🌐 Utilitários de rede (ping, dig, ldapsearch)

**Variáveis principais:**
```bash
START_SSHD=1
SSH_PASSWORD=senha_segura
DATABASE_CHECK=0
MIGRATIONS_CHECK=0
```

**Uso:** Conectar via `ssh otrs@container_ip`

---

### **Jupyter** (`ligero/ligerosmart:jupyter`)
Ambiente Jupyter Notebook com kernel Perl para análise de dados.

**Características:**
- 📊 Jupyter Lab
- 🐪 Kernel Perl (Devel::IPerl)
- 🐍 Python 3 + bibliotecas científicas
- 📈 Acesso direto aos dados do LigeroSmart

**Portas:** `8888`

**Uso:** Ideal para análises avançadas, relatórios customizados e scripts de automação.

---

### **Zabbix Agent** (`ligero/ligerosmart:zabbix-agent`)
Agente Zabbix Alpine para monitoramento de infraestrutura.

**Características:**
- 📊 Monitoramento de recursos
- 🗄️ Clients MariaDB/MySQL e PostgreSQL incluídos
- ✅ Healthcheck automático
- 🔔 Alertas proativos

---

### **Variantes Oracle**
Imagens com suporte a banco de dados Oracle:
- `ligero/ligerosmart:apache2-oracle`
- `ligero/ligerosmart:nginx-oracle`
- `ligero/ligerosmart:scheduler-oracle`

**Adicional:** Drivers Oracle Instant Client e DBD::Oracle.

---

## ✨ Recursos Principais

### 🚀 Instalação Automatizada
- Detecção automática de banco de dados vazio
- Instalação de pacotes (.opm) durante inicialização
- Aplicação automática de migrações de banco
- Configuração inicial com valores padrão

### 💾 Sistema de Backup Avançado

#### **Backup Completo** (`ligero-fullbackup.sh`)
Backup completo de aplicação e banco de dados com compressão.

**Recursos:**
- Dump completo do banco de dados
- Backup do diretório de aplicação
- Exclusão configurável de tabelas e anos
- Compressão gzip ou bzip2
- Nice/Ionice para não impactar performance

#### **Backup Parcial** (`ligero-partialbackup.sh`)
Backup incremental otimizado para rotinas diárias.

**Recursos:**
- Backup de artigos dos últimos N dias
- Menor tamanho e tempo de execução
- Sincronização automática com S3

#### **Sincronização S3** (`s3-sync-backup.sh`)
Upload automático de backups para Amazon S3.

**Recursos:**
- Sincronização multi-perfil AWS
- Retenção configurável (dias)
- Limpeza automática de backups antigos

### 🔄 Migrações de Banco de Dados
Sistema robusto de migrações com controle de versão.

**Características:**
- Aplicação automática na inicialização
- Controle de versão no banco de dados
- Rollback manual disponível
- Logs detalhados

### 🏥 Healthchecks
Monitoramento automático de saúde dos containers.

**Verificações:**
- Conectividade com banco de dados
- Status do servidor web
- Processos críticos em execução
- Tempo de resposta

---

## 🔧 Variáveis de Ambiente

### **Gerais**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `APP_DIR` | `/opt/otrs` | Diretório da aplicação |
| `APP_USER` | `otrs` | Usuário do sistema |
| `START_WEBSERVER` | `0` | Iniciar servidor web (1=sim, 0=não) |
| `START_SCHEDULER` | `0` | Iniciar scheduler (1=sim, 0=não) |
| `START_SSHD` | `0` | Iniciar SSH (1=sim, 0=não) |
| `DEBUG_MODE` | `0` | Modo debug (1=ativo) |

### **Banco de Dados**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `APP_DatabaseType` | `mysql` | Tipo: mysql (para MariaDB/MySQL), postgresql, oracle |
| `APP_DatabaseHost` | - | Hostname do banco (ex: mariadb, mysql, postgres) |
| `APP_Database` | - | Nome do banco de dados |
| `APP_DatabaseUser` | - | Usuário do banco |
| `APP_DatabasePw` | - | Senha do banco |
| `DATABASE_CHECK` | `1` | Verificar conexão na inicialização |
| `MIGRATIONS_CHECK` | `1` | Aplicar migrações automaticamente |

### **E-mail**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `SMTPSERVER` | `mail` | Servidor SMTP |
| `SMTPPORT` | `25` | Porta SMTP |
| `EMAIL` | `otrs@localhost` | E-mail remetente |
| `EMAILPASSWORD` | `passw0rd` | Senha do e-mail |

### **Backup e S3**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `AWS_BUCKET` | - | Bucket S3 para backups |
| `AWS_ACCESS_KEY_ID` | - | Chave de acesso AWS |
| `AWS_SECRET_ACCESS_KEY` | - | Chave secreta AWS |
| `BACKUP_DIR` | `/app-backups` | Diretório de backups |
| `RESTORE_DIR` | `/app-backups/restore` | Diretório para restauração |

### **Nginx (Starman)**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `STARMAN_WORKERS` | `3` | Número de workers Starman |
| `PLACK_ENV` | `deployment` | Ambiente PSGI |
| `NYTPROF` | `start=no` | Profiling NYTProf |

### **Aplicação**

| Variável | Padrão | Descrição |
|----------|--------|--------|
| `ROOT_PASSWORD` | `ligero` | Senha inicial do usuário root@localhost |
| `APP_DefaultLanguage` | - | Idioma padrão (pt_BR, en, es) |
| `APP_CustomerID` | - | Identificador do cliente |
| `APP_NodeID` | `1` | ID do nó (cluster) |

---

## 💾 Sistema de Backup

### Backup Completo

```bash
# Executar backup completo
docker exec -it ligerosmart-web ligero-fullbackup.sh

# Backups são salvos em /app-backups/fullbackup_YYYY-MM-DD_HH-MM/
# ├── DatabaseBackup.sql.gz
# └── Application.tar.gz
```

### Backup Parcial (Incremental)

```bash
# Backup dos últimos 5 dias de artigos
docker exec -it ligerosmart-web ligero-partialbackup.sh

# Salvo em /app-backups/partialbackup_YYYY-MM-DD_HH-MM/
```

### Sincronização com S3

```bash
# Enviar backups para S3
docker exec -it ligerosmart-web s3-sync-backup.sh

# Requer configuração de credenciais AWS
```

### Restauração

```bash
# Restaurar backup
docker run -v /caminho/backup:/app-backups/restore \
  -e RESTORE_DIR=/app-backups/restore \
  ligero/ligerosmart:nginx
```

---

## 🚀 Início Rápido

### Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Banco de dados (MariaDB 10.3+ recomendado ou PostgreSQL 12+)

### Configuração Básica

Consulte o repositório de stack para exemplos completos de docker-compose:

📦 **[LigeroSmart Stack](https://github.com/LigeroSmart/ligerosmart-stack)**

### Exemplo Docker Compose com MariaDB

```yaml
version: '3.8'

services:
  database:
    image: mariadb:10.3
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: ligerosmart
      MYSQL_USER: ligerosmart
      MYSQL_PASSWORD: senha_segura
    volumes:
      - mariadb-data:/var/lib/mysql
    restart: unless-stopped

  ligerosmart:
    image: ligero/ligerosmart:nginx
    ports:
      - "80:80"
    environment:
      APP_DatabaseType: mysql
      APP_DatabaseHost: database
      APP_Database: ligerosmart
      APP_DatabaseUser: ligerosmart
      APP_DatabasePw: senha_segura
      START_WEBSERVER: 1
      START_SCHEDULER: 1
      ROOT_PASSWORD: ligero
    volumes:
      - ligerosmart-data:/opt/otrs
    depends_on:
      - mariadb
    restart: unless-stopped

volumes:
  mariadb-data:
  ligerosmart-data:
```

### Exemplo com Docker Run

#### Com MariaDB (Recomendado)

```bash
docker run -d \
  --name ligerosmart-web \
  -p 80:80 \
  -e APP_DatabaseType=mysql \
  -e APP_DatabaseHost=database \
  -e APP_Database=ligerosmart \
  -e APP_DatabaseUser=ligerosmart \
  -e APP_DatabasePw=senha_segura \
  -e START_WEBSERVER=1 \
  -e START_SCHEDULER=1 \
  -v ligerosmart-data:/opt/otrs \
  ligero/ligerosmart:nginx
```

> **Nota:** Use MariaDB 10.3+ para melhor compatibilidade e performance.

#### Com PostgreSQL

```bash
docker run -d \
  --name ligerosmart-web \
  -p 80:80 \
  -e APP_DatabaseType=postgresql \
  -e APP_DatabaseHost=database \
  -e APP_Database=ligerosmart \
  -e APP_DatabaseUser=ligerosmart \
  -e APP_DatabasePw=senha_segura \
  -e START_WEBSERVER=1 \
  -e START_SCHEDULER=1 \
  -v ligerosmart-data:/opt/otrs \
  ligero/ligerosmart:nginx
```

### Acesso

Após inicialização (1-2 minutos):

```
URL: http://localhost
Usuário: root@localhost
Senha: ligero (padrão, alterar após primeiro login)
```

---

## 🌐 Portas e Volumes

### Portas Expostas

| Serviço | Porta | Protocolo |
|---------|-------|----------|
| Apache2 | 80 | HTTP |
| Nginx | 80 | HTTP |
| Jupyter | 8888 | HTTP |
| SSHD | 22 | SSH |

### Volumes Recomendados

| Path | Descrição |
|------|----------|
| `/opt/otrs` | Aplicação completa |
| `/opt/otrs/var/article` | Anexos de tickets |
| `/opt/otrs/Kernel/Config.pm` | Configuração principal |
| `/app-backups` | Diretório de backups |

---

## 🗄️ Bancos de Dados

### MariaDB (Recomendado)

MariaDB é a opção recomendada para o LigeroSmart devido à sua estabilidade, performance e compatibilidade.

```yaml
environment:
  APP_DatabaseType: mysql
  APP_DatabaseHost: database
  APP_Database: ligerosmart
  APP_DatabaseUser: ligerosmart
  APP_DatabasePw: senha_segura
```

**Versões suportadas:** MariaDB 10.3+

**Recomendação:** MariaDB 10.3 para produção

### MariaDB

```yaml
environment:
  APP_DatabaseType: mysql
  APP_DatabaseHost: database
  APP_Database: ligerosmart
  APP_DatabaseUser: ligerosmart
  APP_DatabasePw: senha_segura
```

**Compatível com:** MariaDB 10.3+

### PostgreSQL

Alternativa ao MariaDB para casos específicos.

```yaml
environment:
  APP_DatabaseType: postgresql
  APP_DatabaseHost: database
  APP_Database: ligerosmart
  APP_DatabaseUser: ligerosmart
  APP_DatabasePw: senha_segura
```

**Versões suportadas:** PostgreSQL 12+

> **Dica:** Para a maioria dos casos de uso, recomendamos MariaDB 10.3 pela sua estabilidade e compatibilidade comprovada com o LigeroSmart.

### Oracle

Use as imagens com sufixo `-oracle`:

```yaml
image: ligero/ligerosmart:nginx-oracle
environment:
  APP_DatabaseType: oracle
  APP_DatabaseHost: oracle.exemplo.com
  APP_Database: XE
  APP_DatabaseUser: ligerosmart
  APP_DatabasePw: senha_segura
```

---

## 🔌 Integrações

### Elasticsearch

Integração nativa para pesquisa full-text avançada.

```yaml
environment:
  APP_ElasticsearchActive: 1
  APP_ElasticsearchHost: elasticsearch
  APP_ElasticsearchPort: 9200
```

**Versão suportada:** Elasticsearch 7.x

### Redis

Cache distribuído para alta performance.

```yaml
environment:
  APP_RedisActive: 1
  APP_RedisHost: redis
  APP_RedisPort: 6379
```

### Zabbix

Monitoramento completo com agente dedicado.

```yaml
services:
  zabbix-agent:
    image: ligero/ligerosmart:zabbix-agent
    environment:
      ZBX_HOSTNAME: ligerosmart-01
      ZBX_SERVER_HOST: zabbix.exemplo.com
```

#### Limite de horas do `count_scheduler_task_old`

Os itens `ligerosmart.count_scheduler_task_old` (MariaDB) e
`ligerosmart.pg.count_scheduler_task_old` (PostgreSQL) contam as tasks do scheduler mais
antigas que N horas. O N vem do parâmetro da chave do item — inteiro, **default 4**
quando a chave vem sem parâmetro:

| Chave do item | Conta tasks com mais de |
|---|---|
| `ligerosmart.count_scheduler_task_old` | 4 horas |
| `ligerosmart.count_scheduler_task_old[12]` | 12 horas |

Para ajustar por cliente sem tocar na stack dele, use uma macro no Zabbix:

1. No template, crie a macro `{$SCHEDULER_TASK_OLD_HOURS}` com valor `4`.
2. Troque a chave do item para
   `ligerosmart.count_scheduler_task_old[{$SCHEDULER_TASK_OLD_HOURS}]`.
3. No host do cliente, sobrescreva a macro com o valor desejado.

Crie a macro antes de trocar a chave: sem ela, o Zabbix envia o texto literal `{$...}` e
o item fica "não suportado". Um valor que não seja inteiro também deixa o item "não
suportado", com a mensagem `horas invalidas: <valor>`.

### MailCatcher (Dev)

Ambiente de desenvolvimento com captura de e-mails.

```yaml
services:
  web:
    image: ligero/ligerosmart:nginx-dev
    environment:
      SMTPSERVER: mailcatcher
      SMTPPORT: 1025
  
  mailcatcher:
    image: schickling/mailcatcher
    ports:
      - "1080:1080"
```

---

## 📚 Documentação

### Links Oficiais

- 📖 **[Documentação Completa](https://docs.ligerosmart.org)**
- 🐳 **[Stack de Produção](https://github.com/LigeroSmart/ligerosmart-stack)**
- 💻 **[Código Fonte](https://github.com/LigeroSmart/ligerosmart)**
- 🌐 **[Site Oficial](https://ligerosmart.com)**

### Suporte

Para questões técnicas e suporte:

- 💬 **Comunidade:** [Grupo do Telegram LigeroSmart](https://t.me/ligerosmart)
- 🐛 **Issues:** [GitHub Issues](https://github.com/LigeroSmart/docker-ligerosmart/issues)

---

## 🔐 Segurança

### Recomendações de Produção

1. **Altere senhas padrão** imediatamente após instalação
2. **Use variáveis de ambiente** para credenciais (não hardcode)
3. **Habilite HTTPS** com certificados válidos (Traefik com Let's Encrypt recomendado)
4. **Configure firewall** para restringir acessos
5. **Mantenha backups** regulares e testados
6. **Atualize regularmente** as imagens Docker
7. **Monitore logs** e configure alertas

---

## 📝 Licença

Este projeto é distribuído sob licença proprietária. Consulte os termos de uso do LigeroSmart.

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Adiciona MinhaFeature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 🏆 Créditos

Desenvolvido e mantido pela equipe **[Complemento](https://complemento.net.br)** para o projeto **LigeroSmart**.

---

<div align="center">

**[⬆ Voltar ao topo](#-ligerosmart---imagens-docker)**

</div>
