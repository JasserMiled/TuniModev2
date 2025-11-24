# TuniMode Backend

Backend Node.js/Express + PostgreSQL pour la marketplace TuniMode.

## Installation

npm install

Copier .env.example en .env et ajuster DATABASE_URL + JWT_SECRET.

Créer la base PostgreSQL puis exécuter :

psql -d tunimode -f sql/tunimode_schema.sql

## Lancement

npm run dev

API sur http://localhost:4000
