# Importação de Dados Legados

Esta pasta contém documentação e arquivos relacionados à importação de dados legados do sistema MySQL antigo.

## Resumo Rápido

Para reimportar dados legados após limpar o banco local:

```bash
cd /workspace/api

# 1. Setup do banco
bundle exec rails db:create db:migrate

# 2. Importar na seguinte ordem (substitua $BASE_PATH pelo caminho dos arquivos):

# Categorias
CATEGORIA_SQL_PATH=$BASE_PATH/acal_categoriasocio.sql \
TAXA_SQL_PATH=$BASE_PATH/acal_taxa.sql \
bundle exec rails legacy_import:categories

# Clientes
PESSOA_SQL_PATH=$BASE_PATH/acal_pessoa.sql \
bundle exec rails legacy_import:customers

# Endereços
ENDERECO_SQL_PATH=$BASE_PATH/acal_endereco.sql \
bundle exec rails legacy_import:addresses

# Análises de Qualidade
TIPO_PARAMETRO_SQL_PATH=$BASE_PATH/acal_tipo_parametro.sql \
PARAMETRO_COLETA_SQL_PATH=$BASE_PATH/acal_parametro_coleta.sql \
bundle exec rails legacy_import:quality_analyses

# Ligações
ENDERECOPESSOA_SQL_PATH=$BASE_PATH/acal_enderecopessoa.sql \
bundle exec rails legacy_import:connections
```

**Exemplo com arquivos em `/workspace/api/.legacy/`:**

```bash
BASE_PATH="/workspace/api/.legacy"
# ... execute os comandos acima substituindo $BASE_PATH
```

## Arquivos Necessários

Você precisa dos seguintes dumps SQL do sistema legado (padrão de nome: `acal_*.sql`):

| Arquivo | Variável de Ambiente | Descrição |
|---------|---------------------|-----------|
| `acal_categoriasocio.sql` | `CATEGORIA_SQL_PATH` | Categorias de ligação |
| `acal_taxa.sql` | `TAXA_SQL_PATH` | Taxas/preços das categorias |
| `acal_pessoa.sql` | `PESSOA_SQL_PATH` | Clientes (Customers) |
| `acal_endereco.sql` | `ENDERECO_SQL_PATH` | Endereços |
| `acal_tipo_parametro.sql` | `TIPO_PARAMETRO_SQL_PATH` | Tipos de parâmetro de qualidade |
| `acal_parametro_coleta.sql` | `PARAMETRO_COLETA_SQL_PATH` | Parâmetros de coleta |
| `acal_enderecopessoa.sql` | `ENDERECOPESSOA_SQL_PATH` | Ligações entre endereços e pessoas |

## Estrutura do Sistema de Importação

```
app/services/legacy_import/
  ├── category_importer.rb         # Importa categorias
  ├── customer_importer.rb         # Importa clientes
  ├── address_importer.rb          # Importa endereços
  ├── connection_importer.rb       # Importa ligações
  └── quality_analysis_importer.rb # Importa análises de qualidade

lib/tasks/
  └── legacy_import.rake           # Tasks Rake para importação
```

## Cada Importador Fornece

- ✅ Validação de dados
- ✅ Tratamento de duplicatas (by legacy_id)
- ✅ Relatório de erros
- ✅ Idempotência (pode rodar múltiplas vezes)

## Ordem de Importação (CRÍTICO!)

1. **Categorias** - Sem dependências
2. **Clientes** - Sem dependências
3. **Endereços** - Sem dependências
4. **Análises de Qualidade** - Sem dependências
5. **Ligações** - Depende de Clientes, Endereços e Categorias

## Exemplo Completo

Se os arquivos estão em `/workspace/api/.legacy/`:

```bash
cd /workspace/api

# 1. Setup do banco
bundle exec rails db:drop db:create db:migrate

# 2. Importar na ordem (use o caminho absoluto completo)
CATEGORIA_SQL_PATH=/workspace/api/.legacy/acal_categoriasocio.sql \
TAXA_SQL_PATH=/workspace/api/.legacy/acal_taxa.sql \
bundle exec rails legacy_import:categories

PESSOA_SQL_PATH=/workspace/api/.legacy/acal_pessoa.sql \
bundle exec rails legacy_import:customers

ENDERECO_SQL_PATH=/workspace/api/.legacy/acal_endereco.sql \
bundle exec rails legacy_import:addresses

TIPO_PARAMETRO_SQL_PATH=/workspace/api/.legacy/acal_tipo_parametro.sql \
PARAMETRO_COLETA_SQL_PATH=/workspace/api/.legacy/acal_parametro_coleta.sql \
bundle exec rails legacy_import:quality_analyses

ENDERECOPESSOA_SQL_PATH=/workspace/api/.legacy/acal_enderecopessoa.sql \
bundle exec rails legacy_import:connections
```

## Verificar Importação

```bash
cd /workspace/api
bundle exec rails console

# Contar registros
> Category.count
> Customer.count
> Address.count
> Connection.count
> QualityAnalysisParameter.count
```

## Troubleshooting

### Erro: Variável de ambiente não definida
Verifique se a sintaxe está correta. Exemplo de erro comum:
```bash
# ❌ Errado
CATEGORIA_SQL_PATH /caminho/arquivo.sql bundle exec rails legacy_import:categories

# ✅ Correto
CATEGORIA_SQL_PATH=/caminho/arquivo.sql bundle exec rails legacy_import:categories
```

### Erro: Arquivo não encontrado
Use o caminho absoluto completo:
```bash
# ❌ Pode não funcionar
CATEGORIA_SQL_PATH=~/arquivo.sql

# ✅ Funciona
CATEGORIA_SQL_PATH=/home/user/arquivo.sql
```

### Muitos registros pulados (inválidos)
Verifique:
- Se o arquivo SQL é um dump MySQL válido
- Se o encoding é UTF-8
- Se todos os campos obrigatórios estão presentes

### Recomeçar a importação

```bash
cd /workspace/api

# Limpar tudo
bundle exec rails db:drop db:create db:migrate

# Reimportar
# ... execute os comandos de importação novamente
```

## Notas Importantes

- ✅ **Idempotente**: Pode executar múltiplas vezes sem problemas
- ✅ **Deduplicação automática**: Por `legacy_id`, não cria duplicatas
- ✅ **Relatórios detalhados**: Mostra o que foi importado, pulado e por quê
- ⚠️ **Ordem crítica**: Sempre respeite a ordem de importação
- ⚠️ **Dependências**: Ligações precisam de Clientes, Endereços e Categorias

## Contato

Para problemas com importação de dados legados, verifique primeiro este README e os importadores em `app/services/legacy_import/`.
