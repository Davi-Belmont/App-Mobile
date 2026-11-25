# StudyPlanner API

Link Repositório API: https://github.com/Davi-Belmont/StudyPlanner

Requisitos: Node.js e Docker.

```bash
docker compose up -d              # sobe o banco (na raiz do projeto)
cd api
cp .env.example .env              # no Windows: copy .env.example .env
npm install
npx prisma migrate deploy         # cria as tabelas
npm run dev                       # API em http://localhost:3000
```

Documentação: http://localhost:3000/docs
