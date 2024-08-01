const { db } = require('./database');
const { Pool } = require('pg');
const fs = require('fs');

// cria conexão com banco de dados
const pool = new Pool({
  ...db,
  ssl: { rejectUnauthorized: false }
});

(async function () {
  // executa o script schema.sql
  const schema = fs.readFileSync('./schema.sql', 'utf8');
  await pool.query(schema)
    .then(() => {
      console.log('Schema executado!');
    })
    .catch(err => {
      console.log('Erro ao executar o schema!', err);
    });

  // testa os triggers
  await testarTriggers();
})();

const produtoValido = { nome: 'Produto A', preco: 10.5, estoque: 5 };
const produtoInvalido1 = { nome: 'Produto B', preco: -5, estoque: 3 };
const produtoInvalido2 = { nome: 'Produto C', preco: 12, estoque: -2 };

async function inserirProduto(produto) {
  try {
    await pool.query('INSERT INTO produtos (nome, preco, estoque) VALUES ($1, $2, $3)', Object.values(produto));
    console.log('Produto inserido com sucesso!', produto);
  } catch (err) {
    console.error('Erro:', err.message);
  }
}

async function testarTriggers() {
  inserirProduto(produtoValido);

  // tenta atualizar
  try {
    await pool.query('UPDATE produtos SET estoque = $1 WHERE id = 1', [7]);
    console.log('Estoque atualizado com sucesso!');
  } catch (err) {
    console.error('Erro:', err.message);
  }

  // tenta inserir invalid
  inserirProduto(produtoInvalido1);
  inserirProduto(produtoInvalido2);
}
